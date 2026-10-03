component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {
	function run() {
		describe( "JWT exclusivamente em Authorization", function() {
			beforeEach( function() {
				setup(); prepareMock( getWireBox().getInstance( "ErroService" ) ).$( "notificar" );
				variables.authJWT = prepareMock( getWireBox().getInstance( "security.JwtAuthenticationService" ) );
				variables.usuarioServiceOriginal = variables.authJWT.$getProperty( "usuarioService", "variables" );
				variables.usuario = new app.models.security.UsuarioAutenticado( { cd_usuario : 123, nm_usuario : "Teste JWT", tx_email : "jwt@example.invalid" } );
				variables.usuarios = createStub().$( "retrieveUserById", variables.usuario ).$( "retrieveUserByUsername", variables.usuario ).$( "isValidCredentials", true );
				variables.authJWT.$property( "usuarioService", "variables", variables.usuarios );
				variables.jwt = getWireBox().getInstance( "JwtService@cbsecurity" );
			} );
			afterEach( function() {
				variables.authJWT.$property( "usuarioService", "variables", variables.usuarioServiceOriginal );
				structDelete( cookie, "cms_access" );
				structDelete( cookie, "cms_refresh" );
			} );

			it( "login sem CSRF emite acesso e refresh; header autoriza a página", function() {
				local.evento = post( route = "/login", params = { txEmail : "jwt@example.invalid", txSenha : "SenhaTeste123!" } );
				local.tokens = local.evento.getRenderData().data;
				expect( local.evento.getStatusCode() ).toBe( 200 );
				expect( local.tokens ).toHaveKey( "refresh_token" );
				expect( isNumeric( local.tokens.expires_at ) ).toBeTrue();
				expect( local.tokens.expires_at ).toBeGT( variables.jwt.toEpoch( now() ) );
				expect( local.evento.getRenderedContent() ).toInclude( '"access_token"' );
				expect( local.evento.getRenderedContent() ).notToInclude( "csrf" );
				setup();
				local.evento = get( route = "/bem-vindo", headers = bearer( local.tokens.access_token ) );
				expect( local.evento.getRenderedContent() ).toInclude( "Teste JWT" );
			} );

			it( "cookies, URL e sessão não substituem o header JWT", function() {
				local.tokens = variables.authJWT.emitirTokens( variables.usuario );
				cookie.cms_access = local.tokens.access_token;
				cookie.cms_refresh = local.tokens.refresh_token;
				setup();
				local.evento = get( route = "/bem-vindo", params = { "x-auth-token" : local.tokens.access_token, access_token : local.tokens.access_token } );
				expect( local.evento.getStatusCode() ).toBe( 401 );
				setup();
				local.evento = post( route = "/cadastro", params = { nmUsuario : "Sem Bearer" } );
				expect( local.evento.getStatusCode() ).toBe( 401 );
			} );

			it( "navegação direta recebe somente uma tela de espera sem dados protegidos", function() {
				local.evento = get( route = "/bem-vindo", headers = { Accept : "text/html" } );
				expect( local.evento.getCurrentView() ).toBe( "autenticacao/carregando" );
				expect( local.evento.getRenderedContent() ).notToInclude( "Teste JWT" );
				expect( local.evento.getRenderedContent() ).toInclude( 'data-jwt-pendente="true"' );
				expect( local.evento.getRenderedContent() ).notToInclude( "csrf" );
			} );

			it( "rejeita assinatura adulterada, emissor incorreto e refresh como acesso", function() {
				local.tokens = variables.authJWT.emitirTokens( variables.usuario );
				local.payload = variables.jwt.decode( local.tokens.access_token );
				local.payload.iss = "outro-emissor";
				for ( local.token in [ local.tokens.access_token & "adulterado", variables.jwt.encode( local.payload ), local.tokens.refresh_token, "invalido" ] ) {
					setup();
					local.evento = get( route = "/bem-vindo", headers = bearer( local.token ) );
					expect( local.evento.getStatusCode() ).toBe( 401 );
				}
			} );

			it( "renova sem CSRF via header; revoga o par antigo e preserva o prazo", function() {
				local.tokens = variables.authJWT.emitirTokens( variables.usuario );
				local.payload = variables.jwt.decode( local.tokens.access_token );
				local.payload.exp = variables.jwt.toEpoch( dateAdd( "s", -60, now() ) );
				setup();
				local.evento = get( route = "/bem-vindo", headers = bearer( variables.jwt.encode( local.payload ) ) );
				expect( local.evento.getStatusCode() ).toBe( 401 );
				setup();
				local.evento = post( route = "/autenticacao/renovar", headers = bearer( local.tokens.refresh_token ) );
				expect( local.evento.getStatusCode() ).toBe( 200 );
				local.novos = local.evento.getRenderData().data;
				expect( local.novos.refresh_expires_at ).toBe( local.tokens.refresh_expires_at );
				expect( local.novos.refresh_token ).notToBe( local.tokens.refresh_token );
				setup();
				local.evento = post( route = "/autenticacao/renovar", headers = bearer( local.tokens.refresh_token ) );
				expect( local.evento.getStatusCode() ).toBe( 401 );
				setup();
				local.evento = get( route = "/bem-vindo", headers = bearer( local.tokens.access_token ) );
				expect( local.evento.getStatusCode() ).toBe( 401 );
				setup();
				local.evento = get( route = "/bem-vindo", headers = bearer( local.novos.access_token ) );
				expect( local.evento.getCurrentView() ).toBe( "autenticacao/boasVindas" );
			} );

			it( "recusa renovação sem header, com acesso ou refresh expirado", function() {
				local.tokens = variables.authJWT.emitirTokens( variables.usuario );
				local.payload = variables.jwt.decode( local.tokens.refresh_token );
				local.payload.exp = variables.jwt.toEpoch( dateAdd( "s", -60, now() ) );
				for ( local.token in [ "", local.tokens.access_token, variables.jwt.encode( local.payload ) ] ) {
					setup();
					local.evento = post( route = "/autenticacao/renovar", headers = len( local.token ) ? bearer( local.token ) : {} );
					expect( local.evento.getStatusCode() ).toBe( 401 );
				}
			} );

			it( "logout via refresh revoga o par e encerra acesso sem CSRF", function() {
				local.tokens = variables.authJWT.emitirTokens( variables.usuario );
				setup();
				local.evento = post( route = "/logout", headers = bearer( local.tokens.refresh_token ) );
				expect( local.evento.getRenderData().data.sucesso ).toBeTrue();
				setup();
				local.evento = get( route = "/bem-vindo", headers = bearer( local.tokens.access_token ) );
				expect( local.evento.getStatusCode() ).toBe( 401 );
				setup();
				local.evento = post( route = "/autenticacao/renovar", headers = bearer( local.tokens.refresh_token ) );
				expect( local.evento.getStatusCode() ).toBe( 401 );
			} );
		} );
	}
	private struct function bearer( required string token ) {
		return { Authorization : "Bearer " & arguments.token };
	}
}
