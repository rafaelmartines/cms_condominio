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
	const estadoModal = { aberto: false, aberturas: 0, descartes: 0 };
	const modal = {
		show() { estadoModal.aberto = true; estadoModal.aberturas++; },
		hide() { estadoModal.aberto = false; },
		dispose() { estadoModal.descartes++; }
	};
	const alerta = {
		textContent: '', classList: { add: (nome) => classes.add(nome), remove: (nome) => classes.delete(nome) },
		setAttribute() {}, focus() { this.focado = true; }
	};
	const login = { setAttribute(nome, valor) { this[nome] = valor; }, querySelector: (seletor) => seletor === '[type="submit"]' ? botao : null, addEventListener: (nome, callback) => { eventos[nome] = callback; } };
	const location = { href: 'http://localhost:10000/login', origin: 'http://localhost:10000', pathname: '/login' };
	const window = {
		bootstrap: { Modal: { getOrCreateInstance: () => modal } },
		fetch: async (url, opcoes) => {
			requisicoes.push({ url, opcoes });
			return requisicoes.length === 1 ? responder(url, opcoes) : new Response('{}', { headers: { 'Content-Type': 'application/json' } });
		}, addEventListener() {}, alert() {}
	};
	runInNewContext(codigo, {
		window, document: {
			body: { dataset: { jwtAutenticado: 'false' } }, addEventListener() {},
			getElementById: (id) => id === 'loginErro' ? alerta : id === 'loginAguarde' ? {} : null,
			querySelector: (seletor) => seletor === '[data-jwt-login]' ? login : null
		}, location, navigator: {}, history: {}, URL, Headers, Response, AbortController, TypeError,
		Request: class extends Request { constructor(url, opcoes) { super(typeof url === 'string' ? new URL(url, location.href) : url, opcoes); } },
		FormData: class { *[Symbol.iterator]() { yield ['txEmail', 'teste@example.invalid']; yield ['txSenha', 'SenhaTeste123!']; } },
		localStorage: { getItem: (chave) => armazenamento.get(chave), setItem: (chave, valor) => armazenamento.set(chave, valor), removeItem: (chave) => armazenamento.delete(chave) },
		setTimeout: (callback, prazo) => { const id = timers.size + 1; timers.set(id, { callback, prazo }); return id; },
		clearTimeout: (id) => timers.delete(id)
	});
	return { enviar: () => eventos.submit({ preventDefault() {} }), requisicoes, armazenamento, timers, botao, alerta, classes, estadoModal, login };
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
	assert.equal(app.estadoModal.aberto, false);
	assert.equal(app.estadoModal.descartes, 1);
	assert.equal(app.login['aria-busy'], 'false');
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
		assert.equal(app.estadoModal.aberto, false);
		assert.equal(app.estadoModal.descartes, 1);
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
	assert.equal(app.estadoModal.aberto, true);
	assert.equal(app.login['aria-busy'], 'true');
	await app.enviar();
	assert.equal(app.estadoModal.aberturas, 1);
	assert.equal(app.requisicoes.length, 1);
	[...app.timers.values()].find((timer) => timer.prazo === 15000).callback();
	await envio;
	assert.match(app.alerta.textContent, /demorou para responder/);
	assert.equal(app.botao.disabled, false);
	assert.equal(app.timers.size, 0);
	assert.equal(app.estadoModal.aberto, false);
	assert.equal(app.estadoModal.descartes, 1);
});

test('navegação não importa estilos noscript que forçam respostas do FAQ abertas', async () => {
	const elementos = [
		{ tipo: 'accordion', classe: 'accordion-collapse collapse' },
		{ tipo: 'noscript', estilo: '.accordion-collapse.collapse { display: block; }' },
		{ tipo: 'noscript', texto: 'JavaScript desativado' },
		{ tipo: 'style', estilo: '.accordion-body { white-space: pre-wrap; }' }
	];
	for (const elemento of elementos) elemento.remove = () => elementos.splice(elementos.indexOf(elemento), 1);
	let importados;
	let substituiu = false;
	const alertas = [];
	const window = { fetch: async () => ({
		status: 200, url: 'http://localhost:10000/faq',
		headers: new Headers({ 'Content-Type': 'text/html' }),
		text: async () => '<html><body>FAQ com alternativa noscript</body></html>'
	}), addEventListener() {}, alert: (mensagem) => alertas.push(mensagem) };
	const document = {
		body: { dataset: { jwtAutenticado: 'false' } }, documentElement: {},
		addEventListener() {}, getElementById: () => null, querySelector: () => null,
		querySelectorAll: () => [],
		importNode(raiz) { importados = raiz.elementos.map((elemento) => ({ ...elemento })); return {}; },
		replaceChild() { substituiu = true; }
	};
	runInNewContext(codigo, {
		window, document, navigator: {}, history: { pushState() {} },
		location: { href: 'http://localhost:10000/', origin: 'http://localhost:10000', pathname: '/' },
		URL, Headers, Request, AbortController, TypeError, setTimeout, clearTimeout,
		localStorage: { getItem: () => null },
		DOMParser: class { parseFromString() { return {
			documentElement: { elementos },
			querySelectorAll: (seletor) => seletor === 'noscript' ? elementos.filter((elemento) => elemento.tipo === 'noscript') : []
		}; } }
	});
	await window.cmsAuth.navigate('/faq');
	assert.deepEqual(alertas, []);
	assert.equal(substituiu, true);
	assert.equal(importados.some((elemento) => elemento.estilo?.includes('display: block')), false);
	assert.equal(importados.some((elemento) => elemento.tipo === 'noscript'), false);
	assert.equal(importados.find((elemento) => elemento.tipo === 'accordion').classe, 'accordion-collapse collapse');
	assert.equal(importados.some((elemento) => elemento.tipo === 'style'), true);
});
