(() => {
	'use strict';
	const storageKey = 'cms.jwt';
	const nativeFetch = window.cmsNativeFetch || (window.cmsNativeFetch = window.fetch.bind(window));
	if (window.cmsAuthLifecycle) window.cmsAuthLifecycle.abort();
	const lifecycle = window.cmsAuthLifecycle = new AbortController();
	const ouvir = (target, name, callback) => target.addEventListener(name, callback, { signal: lifecycle.signal });
	const mensagemFalha = (erro) => erro.name === 'AbortError'
		? 'O servidor demorou para responder. Tente novamente.'
		: erro instanceof TypeError
			? 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.'
			: erro.message;
	const menu = document.getElementById('menuLateralDireito');
	if (menu) ouvir(menu, 'hidden.bs.offcanvas', () => {
		document.querySelector('[data-bs-target="#menuLateralDireito"]')?.focus({ preventScroll: true });
	});
	const liberarMenu = async () => {
		const instancia = menu && window.bootstrap?.Offcanvas.getInstance(menu);
		if (!instancia) return;
		// Aguarda a transição para liberar backdrop, rolagem e foco antes do descarte.
		if (menu.classList.contains('show') || menu.classList.contains('showing') || menu.classList.contains('hiding')) {
			await new Promise((resolve) => {
				menu.addEventListener('hidden.bs.offcanvas', resolve, { once: true });
				if (!menu.classList.contains('hiding')) instancia.hide();
			});
		}
		instancia.dispose();
	};
	const abrirMenu = () => {
		const atual = document.getElementById('menuLateralDireito');
		if (atual && document.body.dataset.jwtAutenticado === 'true') {
			window.bootstrap.Offcanvas.getOrCreateInstance(atual).show();
		}
	};
	let renovacao;
	let timer;
	let navegando = false;
	const ler = () => {
		try { return JSON.parse(localStorage.getItem(storageKey)) || null; }
		catch (_) { return null; }
	};
	const limpar = () => {
		clearTimeout(timer);
		localStorage.removeItem(storageKey);
		localStorage.removeItem('cms.access_token');
	};
	const salvar = (tokens) => {
		if (!tokens.access_token || !tokens.refresh_token || !Number.isFinite(tokens.expires_at)) throw new Error('Resposta de autenticação inválida.');
		localStorage.setItem(storageKey, JSON.stringify(tokens));
		localStorage.removeItem('cms.access_token');
		agendar(tokens);
		return tokens;
	};
	const agendar = (tokens) => {
		clearTimeout(timer);
		timer = setTimeout(() => renovar().catch(() => {}), Math.max(1000, tokens.expires_at * 1000 - Date.now() - 30000));
	};
	const json = async (response) => {
		let dados;
		try { dados = await response.json(); }
		catch (_) {
			const erro = new Error('O servidor retornou uma resposta inválida. Tente novamente em instantes.');
			erro.status = response.status;
			throw erro;
		}
		if (!dados || typeof dados !== 'object' || Array.isArray(dados)) throw new Error('O servidor retornou uma resposta inválida. Tente novamente em instantes.');
		if (!response.ok) {
			const erro = new Error(dados.erro || 'Não foi possível concluir a operação.');
			erro.status = response.status;
			throw erro;
		}
		return dados;
	};
	const renovar = () => {
		if (renovacao) return renovacao;
		const executar = async () => {
			const tokens = ler();
			if (!tokens || tokens.refresh_expires_at * 1000 <= Date.now()) {
				const erro = new Error('Seu acesso expirou. Entre novamente.'); erro.status = 401; throw erro;
			}
			// Outra aba pode ter renovado enquanto aguardávamos o bloqueio.
			if (tokens.expires_at * 1000 > Date.now() + 30000) return tokens;
			return salvar(await json(await nativeFetch('/autenticacao/renovar', {
				method: 'POST', headers: { Authorization: `Bearer ${tokens.refresh_token}`, Accept: 'application/json' },
				credentials: 'same-origin', cache: 'no-store'
			})));
		};
		renovacao = (navigator.locks ? navigator.locks.request('cms-renovar-token', executar) : executar())
			.catch((erro) => {
				if (erro.status === 401) limpar();
				else timer = setTimeout(() => renovar().catch(() => {}), 30000);
				throw erro;
			}).finally(() => { renovacao = null; });
		return renovacao;
	};
	const garantir = async () => {
		const tokens = ler();
		if (tokens && tokens.expires_at * 1000 > Date.now() + 5000) return tokens;
		return renovar();
	};
	const requisicao = async (input, options = {}) => {
		const url = new URL(input instanceof Request ? input.url : input, location.href);
		if (url.origin !== location.origin) return nativeFetch(input, options);
		if (!ler()) return nativeFetch(input, options);
		const original = new Request(input, options);
		const enviar = (tokens) => {
			const headers = new Headers(original.headers);
			headers.set('Authorization', `Bearer ${tokens.access_token}`);
			return nativeFetch(new Request(original.clone(), { headers, credentials: 'same-origin' }));
		};
		let response = await enviar(await garantir());
		if (response.status === 401) {
			// Força a renovação mesmo quando o token ainda parece vigente no cliente.
			const tokens = ler();
			if (tokens) { tokens.expires_at = 0; localStorage.setItem(storageKey, JSON.stringify(tokens)); }
			response = await enviar(await renovar());
			if (response.status === 401) limpar();
		}
		return response;
	};
	window.fetch = requisicao;
	const renderizar = async (response, replace = false) => {
		if (response.status === 401) {
			limpar(); location.assign('/login'); return;
		}
		if (!(response.headers.get('Content-Type') || '').includes('text/html')) {
			await json(response); return;
		}
		const url = new URL(response.url, location.href);
		if (url.origin !== location.origin) throw new Error('Destino de navegação inválido.');
		const html = await response.text();
		await liberarMenu();
		clearTimeout(timer);
		history[replace ? 'replaceState' : 'pushState']({}, '', url.href);
		const pagina = new DOMParser().parseFromString(html, 'text/html');
		lifecycle.abort();
		document.replaceChild(document.importNode(pagina.documentElement, true), document.documentElement);
		// Scripts analisados pelo DOMParser são inertes; recria na ordem do layout.
		for (const original of Array.from(document.querySelectorAll('script'))) {
			// O Bootstrap mantém eventos delegados no document, que sobrevive à navegação.
			if (window.bootstrap && original.getAttribute('src') === '/includes/vendor/bootstrap/5.3.3/js/bootstrap.bundle.min.js') continue;
			const script = document.createElement('script');
			for (const atributo of original.attributes) script.setAttribute(atributo.name, atributo.value);
			script.textContent = original.textContent;
			if (script.src && !script.hasAttribute('async')) {
				script.async = false;
				await new Promise((resolve, reject) => {
					script.onload = resolve;
					script.onerror = () => reject(new Error('Não foi possível carregar os scripts da página.'));
					original.replaceWith(script);
				});
			} else original.replaceWith(script);
		}
	};
	const navegar = async (url, replace = false) => {
		if (navegando) return;
		navegando = true;
		try { await renderizar(await requisicao(url, { headers: { Accept: 'text/html' }, cache: 'no-store' }), replace); }
		catch (erro) { if (erro.status === 401) location.assign('/login'); else window.alert(mensagemFalha(erro)); }
		finally { navegando = false; }
	};
	window.cmsAuth = { fetch: requisicao, navigate: navegar };
	const login = document.querySelector('[data-jwt-login]');
	const alternarSenha = login?.querySelector('[data-alternar-senha]');
	if (alternarSenha) {
		const senha = login.querySelector('#txSenha');
		const icone = alternarSenha.querySelector('i');
		const definirVisibilidade = (visivel) => {
			senha.type = visivel ? 'text' : 'password';
			const descricao = visivel ? 'Ocultar senha' : 'Mostrar senha';
			alternarSenha.setAttribute('aria-label', descricao);
			alternarSenha.title = descricao;
			icone.classList.toggle('bi-eye', !visivel);
			icone.classList.toggle('bi-eye-slash', visivel);
		};
		ouvir(alternarSenha, 'click', () => definirVisibilidade(senha.type === 'password'));
		ouvir(login, 'submit', () => definirVisibilidade(false));
		ouvir(login, 'reset', () => definirVisibilidade(false));
	}
	if (login) ouvir(login, 'submit', async (event) => {
		event.preventDefault();
		const botao = login.querySelector('[type="submit"]');
		const alerta = document.getElementById('loginErro');
		if (botao.disabled) return;
		const controller = new AbortController();
		const limite = setTimeout(() => controller.abort(), 15000);
		botao.disabled = true; alerta.classList.add('d-none');
		try {
			const dados = Object.fromEntries(new FormData(login));
			salvar(await json(await nativeFetch('/auth', {
				method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json' }, body: JSON.stringify(dados),
				credentials: 'same-origin', cache: 'no-store', signal: controller.signal
			})));
			clearTimeout(limite);
			await navegar('/bem-vindo');
			abrirMenu();
		} catch (erro) {
			alerta.textContent = mensagemFalha(erro);
			alerta.classList.remove('d-none');
			alerta.setAttribute('tabindex', '-1');
			alerta.focus();
		}
		finally { clearTimeout(limite); botao.disabled = false; }
	});
	const logout = document.querySelector('[data-jwt-logout]');
	if (logout) ouvir(logout, 'submit', async (event) => {
		event.preventDefault();
		const botao = logout.querySelector('[type="submit"]'); botao.disabled = true;
		clearTimeout(timer);
		try {
			if (renovacao) await renovacao.catch(() => {});
			const tokens = ler();
			if (tokens) {
				const response = await nativeFetch('/logout', { method: 'POST', headers: { Authorization: `Bearer ${tokens.refresh_token}`, Accept: 'application/json' } });
				if (response.status !== 401) await json(response);
			}
			limpar(); location.assign('/login');
		} catch (erro) { botao.disabled = false; window.alert(erro.message); }
	});
	ouvir(document, 'submit', async (event) => {
		const form = event.target;
		if (event.defaultPrevented || form.matches('[data-jwt-login], [data-jwt-logout]') || !ler()) return;
		const url = new URL(form.action, location.href);
		if (url.origin !== location.origin) return;
		event.preventDefault();
		const data = new URLSearchParams(new FormData(form));
		if (event.submitter && event.submitter.name) data.append(event.submitter.name, event.submitter.value);
		const method = (form.method || 'GET').toUpperCase();
		if (method === 'GET') { url.search = data.toString(); await navegar(url); return; }
		const botao = event.submitter;
		if (botao) botao.disabled = true;
		try { await renderizar(await requisicao(url, { method, body: data, headers: { Accept: 'text/html' } })); }
		catch (erro) { if (erro.status === 401) location.assign('/login'); else window.alert(erro.message); }
		finally { if (botao) botao.disabled = false; }
	});
	ouvir(document, 'click', (event) => {
		const link = event.target.closest('a[href]');
		if (!link || event.defaultPrevented || event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey || link.target || link.hasAttribute('download') || !ler()) return;
		const url = new URL(link.href);
		if (url.origin !== location.origin || url.pathname === location.pathname && url.hash) return;
		event.preventDefault(); navegar(url);
	});
	// DataTables e jQuery usam a mesma validação de prazo e renovação do fetch.
	if (window.jQuery) window.jQuery.ajaxTransport('+*', (options) => {
		if (new URL(options.url, location.href).origin !== location.origin || !ler()) return;
		const controller = new AbortController();
		return {
			send(headers, complete) {
				requisicao(options.url, {
					method: options.type, headers, signal: controller.signal,
					body: /^(GET|HEAD)$/i.test(options.type) ? undefined : options.data
				}).then(async (response) => {
					const responseHeaders = Array.from(response.headers.entries()).map(([name, value]) => `${name}: ${value}`).join('\r\n');
					complete(response.status, response.statusText, { text: await response.text() }, responseHeaders);
				}).catch((erro) => complete(0, erro.name === 'AbortError' ? 'abort' : 'error'));
			},
			abort() { controller.abort(); }
		};
	});
	ouvir(window, 'storage', (event) => {
		if (event.key === storageKey) {
			const tokens = ler();
			if (tokens) agendar(tokens);
			else { clearTimeout(timer); if (document.body.dataset.jwtAutenticado === 'true') location.assign('/login'); }
		}
	});
	ouvir(window, 'popstate', () => location.reload());
	ouvir(window, 'pageshow', (event) => { if (event.persisted) location.reload(); });
	(async () => {
		try {
			const tokens = ler();
			if (!tokens) {
				if (document.body.dataset.jwtPendente === 'true') location.replace('/login');
				return;
			}
			agendar(tokens);
			await garantir();
			if (login) { await navegar('/bem-vindo', true); abrirMenu(); }
			else if (document.body.dataset.jwtAutenticado !== 'true') await navegar(location.href, true);
		} catch (erro) { if (erro.status === 401) location.assign('/login'); }
	})();
})();
