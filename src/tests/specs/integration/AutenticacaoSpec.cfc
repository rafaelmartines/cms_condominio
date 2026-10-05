component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {
	function run() {
		describe( "Autenticação e cadastro restrito com Bearer", function() {
			beforeEach( function() { setup(); prepareMock( getWireBox().getInstance( "ErroService" ) ).$( "notificar" ); } );
			it( "recusa visitantes inclusive em eventos diretos", function() {
				for ( local.rota in [ "/categorias", "/categorias/adicionar", "/cadastro", "/bem-vindo" ] ) {
					setup();
					local.evento = get( route = local.rota );
					expect( local.evento.getStatusCode() ).toBe( 401 );
				}
				setup();
				local.evento = execute( event = "Categorias.index", renderResults = true );
				expect( local.evento.getStatusCode() ).toBe( 401 );
			} );
			it( "exibe login sem CSRF e valida campos no POST", function() {
				local.evento = get( route = "/login" );
				expect( local.evento.getCurrentView() ).toBe( "autenticacao/login" );
				expect( local.evento.getRenderedContent() ).notToInclude( "csrf" );
				setup();
				local.evento = post( route = "/login" );
				expect( local.evento.getStatusCode() ).toBe( 422 );
				setup();
				local.evento = post( route = "/login", params = { txEmail : [], txSenha : {} } );
				expect( local.evento.getStatusCode() ).toBe( 422 );
			} );
			it( "armazena hashes distintos e verifica senhas com comparação sensível a maiúsculas", function() {
				local.service = getWireBox().getInstance( "security.SenhaService" );
				local.hash = local.service.gerarHash( "SenhaTeste123!" );
				// Vetor gerado por hashlib.pbkdf2_hmac, usado pelo script da primeira conta.
				expect( local.service.verificar( "SenhaTeste123!", "pbkdf2-sha256$600000$AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=$hEwj1nw9CoqrkvgTEyqqSolqkPCq0XpNB+kpRQlCmKA=" ) ).toBeTrue();
				expect( local.hash ).notToBe( local.service.gerarHash( "SenhaTeste123!" ) );
				expect( local.service.verificar( "SenhaTeste123!", local.hash ) ).toBeTrue();
				expect( local.service.verificar( "senhateste123!", local.hash ) ).toBeFalse();
				expect( local.service.verificar( "SenhaTeste123!", "invalido" ) ).toBeFalse();
			} );
			it( "login retorna JSON em falhas internas e exige POST no evento direto", function() {
				local.auth = prepareMock( getWireBox().getInstance( "security.JwtAuthenticationService" ) );
				local.original = local.auth.authenticate;
				local.auth.$( "authenticate" ).$throws( type = "Database", message = "Detalhe interno" );
				try {
					local.evento = post( route = "/login", params = { txEmail : "teste@example.invalid", txSenha : "SenhaTeste123!" } );
					expect( local.evento.getStatusCode() ).toBe( 500 );
					expect( deserializeJSON( local.evento.getRenderedContent() ).erro ).toInclude( "Não foi possível" );
					expect( local.evento.getRenderedContent() ).notToInclude( "Detalhe interno" );
				} finally {
					local.auth.authenticate = local.original;
					local.auth.$property( "authenticate", "variables", local.original );
				}
				setup();
				local.evento = get( route = "/Autenticacao/entrar" );
					expect( local.evento.getStatusCode() ).toBe( 405 );
					expect( deserializeJSON( local.evento.getRenderedContent() ).erro ).toInclude( "POST" );
			} );

			it( "valida cadastro, confirmação de senha e nomes sem validar códigos", function() {
				local.dto = getWireBox().getInstance( "UsuarioDTO" );
				local.manager = getWireBox().getInstance( "ValidationManager@cbvalidation" );
				local.dto.setNmUsuario( "Teste" );
				local.dto.setTxEmail( "teste@example.invalid" );
				local.dto.setTxSenha( "SenhaTeste123!" );
				local.dto.setTxConfirmacaoSenha( "OutraSenha123!" );
				expect( local.manager.validate( target = local.dto, profiles = "cadastro" ).hasErrors( "txConfirmacaoSenha" ) ).toBeTrue();
				local.dto.setTxConfirmacaoSenha( "senhateste123!" );
				expect( local.manager.validate( target = local.dto, profiles = "cadastro" ).hasErrors( "txConfirmacaoSenha" ) ).toBeTrue();
				local.dto.setTxConfirmacaoSenha( [ "SenhaTeste123!" ] );
				expect( local.manager.validate( target = local.dto, profiles = "cadastro" ).hasErrors( "txConfirmacaoSenha" ) ).toBeTrue();
				local.dto.setTxConfirmacaoSenha( "SenhaTeste123!" );
				expect( local.manager.validate( target = local.dto, profiles = "cadastro" ).hasErrors() ).toBeFalse();
			} );

			it( "valida credenciais reais, cadastra com JWT e encerra o acesso", function() {
				transaction {
					try {
						local.email = lCase( createUUID() ) & "@example.invalid";
						local.dto = getWireBox().getInstance( "UsuarioDTO" );
						local.dto.setNmUsuario( "Usuário de teste" );
						local.dto.setTxEmail( local.email );
						local.dto.setTxSenha( "SenhaTeste123!" );
						local.dto.setTxConfirmacaoSenha( "SenhaTeste123!" );
						local.service = getWireBox().getInstance( "UsuarioService" );
						local.service.cadastrar( local.dto );
						expect( function() { service.cadastrar( dto ); } ).toThrow( "UsuarioDuplicado" );
						local.evento = post( route = "/login", params = { txEmail : local.email, txSenha : "SenhaErrada123!" } );
						expect( local.evento.getStatusCode() ).toBe( 401 );
						expect( local.evento.getRenderedContent() ).notToInclude( "SenhaErrada123!" );
						setup();
						local.evento = post( route = "/login", params = { txEmail : local.email, txSenha : "SenhaTeste123!" } );
						local.tokens = local.evento.getRenderData().data;
						local.headers = { Authorization : "Bearer " & local.tokens.access_token };
						for ( local.rota in [ "/bem-vindo", "/categorias", "/cadastro" ] ) {
							setup();
							local.evento = get( route = local.rota, headers = local.headers );
							expect( local.evento.getStatusCode() ).toBe( 200 );
						}
						setup();
						local.evento = post( route = "/cadastro", headers = local.headers, params = { nmUsuario : "Novo usuário", txEmail : "novo-" & local.email, txSenha : "NovaSenha12345!", txConfirmacaoSenha : "NovaSenha12345!" }, renderResults = false );
						expect( local.evento.getValue( "relocate_URI", "" ) ).toBe( "/cadastro" );
						expect( getWireBox().getInstance( "security.JwtAuthenticationService" ).getUser().getTxEmail() ).toBe( local.email );
						setup();
						local.evento = post( route = "/logout", headers = { Authorization : "Bearer " & local.tokens.refresh_token } );
						expect( local.evento.getStatusCode() ).toBe( 200 );
						setup();
						local.evento = get( route = "/categorias", headers = local.headers );
						expect( local.evento.getStatusCode() ).toBe( 401 );
					} finally { transaction action="rollback"; }
				}
			} );
		} );
	}
}
