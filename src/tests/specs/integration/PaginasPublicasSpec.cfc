component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {
	function run() {
		describe( "Página inicial e listagem pública de fornecedores", function() {
			beforeEach( function() {
				setup();
				prepareMock( getWireBox().getInstance( "ErroService" ) ).$( "notificar" );
			} );

			it( "exibe atalhos na página inicial sem carregar a listagem", function() {
				local.event = get( route = "/" );
				expect( local.event.getStatusCode() ).toBe( 200 );
				expect( local.event.getCurrentView() ).toBe( "main/index" );
				expect( local.event.getRenderedContent() ).toInclude( "Principais Serviços" );
				expect( local.event.getRenderedContent() ).toInclude( 'href="/fornecedores"' );
				expect( local.event.getRenderedContent() ).toInclude( 'href="/faq"' );
				expect( local.event.getRenderedContent() ).toInclude( 'href="https://uclass.com.br/bn/vbstar/"' );
				expect( local.event.getRenderedContent() ).notToInclude( 'id="minhaTabela"' );
				expect( local.event.getRenderedContent() ).notToInclude( 'id="formFiltroFornecedores"' );
				expect( local.event.privateValueExists( "categorias" ) ).toBeFalse();
			} );

			it( "abre a listagem sem autenticação e mantém filtros e carregamento pela API", function() {
				local.event = get( route = "/fornecedores" );
				expect( local.event.getStatusCode() ).toBe( 200 );
				expect( local.event.getCurrentView() ).toBe( "fornecedores/index" );
				expect( local.event.getRenderedContent() ).toInclude( 'id="minhaTabela"' );
				expect( local.event.getRenderedContent() ).toInclude( 'id="filtroNome"' );
				expect( local.event.getRenderedContent() ).toInclude( 'id="filtroCategoria"' );
				expect( local.event.getPrivateValue( "scripts" ) ).toInclude( "/api/fornecedores" );
				expect( local.event.getRenderedContent() ).toInclude( "Voltar ao início" );
			} );
			it( "mantém indicação pública em uma view própria e encaminha para a API de indicação", function() {
				local.event = get( route = "/fornecedores/indicar" );
				expect( local.event.getStatusCode() ).toBe( 200 );
				expect( local.event.getCurrentView() ).toBe( "fornecedores/indicar" );
				expect( local.event.getPrivateValue( "scripts" ) ).toInclude( "/api/fornecedores/indicacao" );
				expect( local.event.getRenderedContent() ).notToInclude( 'id="minhaTabela"' );
			} );

			it( "protege listagem administrativa e cadastro sem restringir a lista pública", function() {
				for ( local.rota in [ "/administracao/fornecedores", "/fornecedores/adicionar" ] ) {
					setup();
					local.event = get( route = local.rota, headers = { Accept : "application/json" } );
					expect( local.event.getStatusCode() ).toBe( 401 );
				}
				setup();
				local.event = execute( event = "Fornecedores.gestao" );
				expect( local.event.getRenderData().statusCode ).toBe( 401 );
			} );

			it( "abre gestão e cadastro em views distintas com JWT válido", function() {
				transaction {
					try {
						local.usuario = getWireBox().getInstance( "Usuario" ).create( {
							nmUsuario : "Teste rotas fornecedores", txEmail : lCase( createUUID() ) & "@example.invalid", txSenhaHash : "não utilizada neste teste"
						} );
						local.tokens = getWireBox().getInstance( "security.JwtAuthenticationService" ).emitirTokens( getWireBox().getInstance( "UsuarioService" ).retrieveUserById( local.usuario.getCdUsuario() ) );
						local.headers = { Authorization : "Bearer " & local.tokens.access_token, Accept : "text/html" };
						local.event = get( route = "/administracao/fornecedores", headers = local.headers );
						expect( local.event.getStatusCode() ).toBe( 200 );
						expect( local.event.getCurrentView() ).toBe( "fornecedores/gestao" );
						expect( local.event.getRenderedContent() ).toInclude( 'id="minhaTabela"' );
						expect( local.event.getRenderedContent() ).toInclude( 'href="/fornecedores/adicionar"' );
						expect( local.event.getRenderedContent() ).toInclude( 'href="/administracao/fornecedores"' );
						setup();
						local.event = get( route = "/fornecedores/adicionar", headers = local.headers );
						expect( local.event.getStatusCode() ).toBe( 200 );
						expect( local.event.getCurrentView() ).toBe( "fornecedores/adicionar" );
						expect( local.event.getRenderedContent() ).toInclude( 'action="/fornecedores/adicionar"' );
						expect( local.event.getRenderedContent() ).notToInclude( 'id="minhaTabela"' );
					} finally { transaction action="rollback"; }
				}
			} );
		} );
	}
}
