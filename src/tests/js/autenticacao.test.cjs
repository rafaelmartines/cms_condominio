const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const { runInNewContext } = require('node:vm');

const codigo = readFileSync(join(__dirname, '../../includes/js/autenticacao.js'), 'utf8');
const tokens = { access_token: 'jwt-teste', refresh_token: 'refresh-teste', expires_at: Date.now() / 1000 + 3600 };

function ambiente(responder) {
	const eventos = {};
	const requisicoes = [];
	const armazenamento = new Map();
	const timers = new Map();
	const classes = new Set(['d-none']);
	const botao = { disabled: false };
	const alerta = {
		textContent: '', classList: { add: (nome) => classes.add(nome), remove: (nome) => classes.delete(nome) },
		setAttribute() {}, focus() { this.focado = true; }
	};
	const login = { querySelector: () => botao, addEventListener: (nome, callback) => { eventos[nome] = callback; } };
	const location = { href: 'http://localhost:10000/login', origin: 'http://localhost:10000', pathname: '/login' };
	const window = {
		fetch: async (url, opcoes) => {
			requisicoes.push({ url, opcoes });
			return requisicoes.length === 1 ? responder(url, opcoes) : new Response('{}', { headers: { 'Content-Type': 'application/json' } });
		}, addEventListener() {}, alert() {}
	};
	runInNewContext(codigo, {
		window, document: {
			body: { dataset: { jwtAutenticado: 'false' } }, addEventListener() {},
			getElementById: (id) => id === 'loginErro' ? alerta : null,
			querySelector: (seletor) => seletor === '[data-jwt-login]' ? login : null
		}, location, navigator: {}, history: {}, URL, Headers, Response, AbortController, TypeError,
		Request: class extends Request { constructor(url, opcoes) { super(typeof url === 'string' ? new URL(url, location.href) : url, opcoes); } },
		FormData: class { *[Symbol.iterator]() { yield ['txEmail', 'teste@example.invalid']; yield ['txSenha', 'SenhaTeste123!']; } },
		localStorage: { getItem: (chave) => armazenamento.get(chave), setItem: (chave, valor) => armazenamento.set(chave, valor), removeItem: (chave) => armazenamento.delete(chave) },
		setTimeout: (callback, prazo) => { const id = timers.size + 1; timers.set(id, { callback, prazo }); return id; },
		clearTimeout: (id) => timers.delete(id)
	});
	return { enviar: () => eventos.submit({ preventDefault() {} }), requisicoes, armazenamento, timers, botao, alerta, classes };
}

test('login envia POST JSON na mesma origem, armazena JWT e libera o botão', async () => {
	const app = ambiente(() => new Response(JSON.stringify(tokens), { headers: { 'Content-Type': 'application/json' } }));
	await app.enviar();
	const { url, opcoes } = app.requisicoes[0];
	assert.equal(url, '/auth');
	assert.equal(opcoes.method, 'POST');
	assert.equal(opcoes.headers['Content-Type'], 'application/json');
	assert.equal(opcoes.credentials, 'same-origin');
	assert.deepEqual(JSON.parse(opcoes.body), { txEmail: 'teste@example.invalid', txSenha: 'SenhaTeste123!' });
	assert.equal(JSON.parse(app.armazenamento.get('cms.jwt')).access_token, tokens.access_token);
	assert.equal(app.botao.disabled, false);
});

for (const status of [400, 401, 422, 500]) {
	test(`login exibe a mensagem JSON de erro HTTP ${status}`, async () => {
		const app = ambiente(() => new Response(JSON.stringify({ erro: 'Mensagem clara do servidor.' }), { status }));
		await app.enviar();
		assert.equal(app.alerta.textContent, 'Mensagem clara do servidor.');
		assert.equal(app.botao.disabled, false);
		assert.equal(app.classes.has('d-none'), false);
		assert.equal(app.alerta.focado, true);
		assert.equal(app.armazenamento.has('cms.jwt'), false);
	});
}

test('falha de conexão é capturada e permite nova tentativa', async () => {
	const app = ambiente(() => { throw new TypeError('Failed to fetch'); });
	await app.enviar();
	assert.match(app.alerta.textContent, /Não foi possível conectar ao servidor/);
	assert.equal(app.botao.disabled, false);
});

test('resposta HTML inválida é capturada sem armazenar token', async () => {
	const app = ambiente(() => new Response('<html>Erro</html>', { status: 500 }));
	await app.enviar();
	assert.match(app.alerta.textContent, /resposta inválida/);
	assert.equal(app.armazenamento.has('cms.jwt'), false);
});

test('tempo limite cancela o login e um segundo submit não duplica o POST', async () => {
	const app = ambiente((url, opcoes) => new Promise((resolve, reject) => {
		opcoes.signal.addEventListener('abort', () => reject(Object.assign(new Error(), { name: 'AbortError' })));
	}));
	const envio = app.enviar();
	await app.enviar();
	assert.equal(app.requisicoes.length, 1);
	[...app.timers.values()].find((timer) => timer.prazo === 15000).callback();
	await envio;
	assert.match(app.alerta.textContent, /demorou para responder/);
	assert.equal(app.botao.disabled, false);
	assert.equal(app.timers.size, 0);
});
