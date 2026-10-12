component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {
	function run() {
		describe( "FAQ público e administração", function() {
			beforeEach( function() {
				setup();
				prepareMock( getWireBox().getInstance( "ErroService" ) ).$( "notificar" );
			} );

			it( "valida pergunta, resposta, busca e identificador antes de consultar o banco", function() {
				local.service = getWireBox().getInstance( "FaqService" );
				for ( local.valor in [ "", "   ", [], {}, repeatString( "a", 301 ) ] ) {
					local.dto = novoDTO();
					local.dto.setTxPergunta( local.valor );
					local.caso = { service : local.service, dto : local.dto };
					expect( function() { caso.service.criar( caso.dto ); } ).toThrow( "FaqInvalido" );
				}
				for ( local.valor in [ "", "   ", [], {}, repeatString( "a", 10001 ) ] ) {
					local.dto = novoDTO();
					local.dto.setTxResposta( local.valor );
					local.caso = { service : local.service, dto : local.dto };
					expect( function() { caso.service.criar( caso.dto ); } ).toThrow( "FaqInvalido" );
				}
				for ( local.valor in [ "", "0", "-1", "1.5", "2147483648", [], {}, "1 OR 1=1" ] ) {
					local.caso = { service : local.service, id : local.valor, dto : novoDTO() };
					expect( function() { caso.service.obterPergunta( caso.id ); } ).toThrow( "FaqInvalido" );
					expect( function() { caso.service.editar( caso.id, caso.dto ); } ).toThrow( "FaqInvalido" );
					expect( function() { caso.service.excluir( caso.id ); } ).toThrow( "FaqInvalido" );
					expect( function() { caso.service.reativar( caso.id ); } ).toThrow( "FaqInvalido" );
				}
				for ( local.valor in [ [], {}, repeatString( "a", 301 ) ] ) {
					local.caso = { service : local.service, busca : local.valor };
					expect( function() { caso.service.listarPublicas( caso.busca ); } ).toThrow( "FaqInvalido" );
				}
			} );

			it( "persiste o ciclo completo e preserva a exclusão durante a edição", function() {
				transaction {
					try {
						local.service = getWireBox().getInstance( "FaqService" );
						local.dto = novoDTO();
						local.id = local.service.criar( local.dto );
						expect( local.service.obterPergunta( local.id ).txPergunta ).toBe( trim( local.dto.getTxPergunta() ) );
						expect( local.service.listarPublicas( trim( local.dto.getTxPergunta() ) ) ).toHaveLength( 1 );
						local.service.excluir( local.id );
						expect( local.service.listarPublicas( trim( local.dto.getTxPergunta() ) ) ).toBeEmpty();
						local.dto.setTxResposta( "Resposta editada" );
						local.service.editar( local.id, local.dto );
						expect( local.service.obterPergunta( local.id ).inAtivo ).toBeFalse();
						expect( local.service.obterPergunta( local.id ).txResposta ).toBe( "Resposta editada" );
						for ( local.tentativa in [ 1, 2 ] ) local.service.reativar( local.id );
						expect( local.service.obterPergunta( local.id ).inAtivo ).toBeTrue();
						expect( local.service.listarPublicas( trim( local.dto.getTxPergunta() ) ) ).toHaveLength( 1 );
					} finally { transaction action="rollback"; }
				}
			} );

			it( "busca por pergunta sem distinguir acentos, trata texto literal e ordena", function() {
				transaction {
					try {
						local.service = getWireBox().getInstance( "FaqService" );
						local.sufixo = createUUID();
						local.dto = novoDTO();
						local.dto.setTxPergunta( "B São José 100%_ " & local.sufixo );
						local.dto.setTxResposta( "Resposta exclusiva " & local.sufixo );
						local.service.criar( local.dto );
						local.dto.setTxPergunta( "A São José 100%_ " & local.sufixo );
						local.service.criar( local.dto );
						local.dto.setTxPergunta( "C São José 100%_ " & local.sufixo );
						local.idExcluida = local.service.criar( local.dto );
						local.service.excluir( local.idExcluida );
						local.resultado = local.service.listarPublicas( "SAO JOSE 100%_ " & local.sufixo );
						expect( local.resultado ).toHaveLength( 2 );
						expect( left( local.resultado[ 1 ].txPergunta, 1 ) ).toBe( "A" );
						expect( left( local.resultado[ 2 ].txPergunta, 1 ) ).toBe( "B" );
						expect( local.service.listarPublicas( "Resposta exclusiva " & local.sufixo ) ).toBeEmpty();
						expect( local.service.listarPublicas( "' OR 1=1 -- " & local.sufixo ) ).toBeEmpty();
						expect( local.service.listarPublicas( "inexistente " & local.sufixo ) ).toBeEmpty();
						local.gestao = local.service.listarParaGestao().filter( function( pergunta ) { return pergunta.cdFaq EQ idExcluida; } );
						expect( local.gestao ).toHaveLength( 1 );
					} finally { transaction action="rollback"; }
				}
			} );

			it( "trata identificadores inexistentes sem acessar o primeiro elemento vazio", function() {
				local.service = getWireBox().getInstance( "FaqService" );
				local.dto = novoDTO();
				expect( function() { service.obterPergunta( 2147483647 ); } ).toThrow( "FaqNaoEncontrado" );
				expect( function() { service.editar( 2147483647, dto ); } ).toThrow( "FaqNaoEncontrado" );
				expect( function() { service.excluir( 2147483647 ); } ).toThrow( "FaqNaoEncontrado" );
				expect( function() { service.reativar( 2147483647 ); } ).toThrow( "FaqNaoEncontrado" );
			} );

			it( "consulta publicamente, escapa conteúdo e mantém somente o menu público sem login", function() {
				transaction {
					try {
						local.dto = novoDTO();
						local.sufixo = createUUID();
						local.dto.setTxPergunta( "<script>pergunta</script> " & local.sufixo );
						local.dto.setTxResposta( "<img src=x onerror=alert(1)>" );
						getWireBox().getInstance( "FaqService" ).criar( local.dto );
						local.event = get( route = "/faq", params = { busca : local.sufixo } );
						expect( local.event.getStatusCode() ).toBe( 200 );
						expect( local.event.getRenderedContent() ).toInclude( "accordion-button collapsed" );
						expect( local.event.getRenderedContent() ).notToInclude( "<script>pergunta</script>" );
						expect( local.event.getRenderedContent() ).notToInclude( "<img src=x onerror=alert(1)>" );
						expect( local.event.getRenderedContent() ).toInclude( 'href="/faq"' );
						expect( local.event.getRenderedContent() ).notToInclude( 'href="/administracao/faq"' );
					} finally { transaction action="rollback"; }
				}
			} );

			it( "mostra estado vazio e rejeita busca complexa", function() {
				local.event = get( route = "/faq", params = { busca : createUUID() } );
				expect( local.event.getRenderedContent() ).toInclude( "Nenhuma pergunta encontrada" );
				setup();
				local.event = get( route = "/faq", params = { busca : [] } );
				expect( local.event.getStatusCode() ).toBe( 422 );
			} );

			it( "bloqueia todas as ações administrativas sem JWT", function() {
				for ( local.caso in [
					{ rota : "/administracao/faq", metodo : "GET" },
					{ rota : "/administracao/faq/adicionar", metodo : "GET" },
					{ rota : "/administracao/faq/adicionar", metodo : "POST" },
					{ rota : "/administracao/faq/1/editar", metodo : "GET" },
					{ rota : "/administracao/faq/1/editar", metodo : "POST" },
					{ rota : "/administracao/faq/1/excluir", metodo : "GET" },
					{ rota : "/administracao/faq/1/excluir", metodo : "POST" },
					{ rota : "/administracao/faq/1/reativar", metodo : "POST" }
				] ) {
					setup();
					local.event = request( route = local.caso.rota, method = local.caso.metodo, headers = { Accept : "application/json" } );
					expect( local.event.getStatusCode() ).toBe( 401 );
				}
			} );

			it( "gerencia com JWT válido, preserva os campos no erro e ignora estado enviado pelo cliente", function() {
				transaction {
					try {
						local.headers = autenticar();
						local.dto = novoDTO();
						local.id = getWireBox().getInstance( "FaqService" ).criar( local.dto );
						local.event = get( route = "/administracao/faq", headers = local.headers );
						expect( local.event.getRenderedContent() ).toInclude( 'href="/administracao/faq"' );
						setup();
						local.event = post( route = "/administracao/faq/#local.id#/editar", headers = local.headers, params = { txPergunta : "Pergunta preservada", txResposta : " " } );
						expect( local.event.getStatusCode() ).toBe( 422 );
						expect( local.event.getCurrentView() ).toBe( "faq/admin/formulario" );
						expect( local.event.getPrivateValue( "pergunta" ).txPergunta ).toBe( "Pergunta preservada" );
						expect( local.event.getRenderedContent() ).toInclude( encodeForHTMLAttribute( "Pergunta preservada" ) );
						setup();
						local.event = post( route = "/administracao/faq/adicionar", headers = local.headers, params = { txPergunta : [], txResposta : {} } );
						expect( local.event.getStatusCode() ).toBe( 422 );
						setup();
						local.nome = "Nova " & createUUID();
						local.event = post( route = "/administracao/faq/adicionar", headers = local.headers, params = { txPergunta : local.nome, txResposta : "Resposta", inAtivo : false, cdFaq : 2147483647 }, renderResults = false );
						expect( local.event.getValue( "relocate_statusCode", 0 ) ).toBe( 303 );
						expect( getWireBox().getInstance( "FaqService" ).listarPublicas( local.nome ) ).toHaveLength( 1 );
						setup();
						local.event = post( route = "/administracao/faq/#local.id#/excluir", headers = local.headers, renderResults = false );
						expect( local.event.getValue( "relocate_URI", "" ) ).toBe( "/administracao/faq" );
						expect( getWireBox().getInstance( "FaqService" ).obterPergunta( local.id ).inAtivo ).toBeFalse();
						setup();
						local.event = post( route = "/administracao/faq/#local.id#/editar", headers = local.headers, params = { txPergunta : "Editada", txResposta : "Resposta editada", inAtivo : true }, renderResults = false );
						expect( getWireBox().getInstance( "FaqService" ).obterPergunta( local.id ).inAtivo ).toBeFalse();
						setup();
						local.event = post( route = "/administracao/faq/#local.id#/reativar", headers = local.headers, renderResults = false );
						expect( getWireBox().getInstance( "FaqService" ).obterPergunta( local.id ).inAtivo ).toBeTrue();
						setup();
						local.event = get( route = "/administracao/faq/2147483647/editar", headers = local.headers );
						expect( local.event.getStatusCode() ).toBe( 404 );
					} finally { transaction action="rollback"; }
				}
			} );

			it( "recusa gravação por GET inclusive nas rotas convencionais", function() {
				transaction {
					try {
						local.headers = autenticar();
						for ( local.acao in [ "criar", "salvar", "excluir", "reativar" ] ) {
							setup();
							local.event = get( route = "/FaqAdmin/#local.acao#", headers = local.headers );
							expect( local.event.getStatusCode() ).toBe( 405 );
						}
					} finally { transaction action="rollback"; }
				}
			} );
		} );
	}

	private any function novoDTO() {
		local.dto = new app.models.dto.FaqDTO();
		local.dto.setTxPergunta( "  Pergunta teste " & createUUID() & "  " );
		local.dto.setTxResposta( "  Resposta teste  " );
		return local.dto;
	}

	private struct function autenticar() {
		local.usuario = getWireBox().getInstance( "Usuario" ).create( {
			nmUsuario : "Teste FAQ", txEmail : lCase( createUUID() ) & "@example.invalid", txSenhaHash : "não utilizada neste teste"
		} );
		local.auth = getWireBox().getInstance( "security.JwtAuthenticationService" );
		local.tokens = local.auth.emitirTokens( getWireBox().getInstance( "UsuarioService" ).retrieveUserById( local.usuario.getCdUsuario() ) );
		return { Authorization : "Bearer " & local.tokens.access_token, Accept : "text/html" };
	}
}
