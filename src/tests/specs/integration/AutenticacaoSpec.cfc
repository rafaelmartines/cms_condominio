component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {

	function run() {
		describe( "Autenticação e cadastro restrito", function() {
			beforeEach( function() {
				setup();
				getWireBox().getInstance( "authenticationService@cbauth" ).logout( quiet = true );
			} );

			afterEach( function() {
				getWireBox().getInstance( "authenticationService@cbauth" ).logout( quiet = true );
			} );

			it( "redireciona visitantes nas categorias, cadastro e boas-vindas", function() {
				for ( local.rota in [ "/categorias", "/categorias/adicionar", "/categorias/1/editar", "/categorias/1/inativar", "/cadastro", "/bem-vindo" ] ) {
					setup();
					local.evento = get( route = local.rota, renderResults = false );
					expect( local.evento.getValue( "relocate_event", "" ) ).toBe( "login" );
				}
				for ( local.rota in [ "/categorias/adicionar", "/categorias/1/editar", "/categorias/1/inativar", "/cadastro" ] ) {
					setup();
					local.evento = post( route = local.rota, renderResults = false );
					expect( local.evento.getValue( "relocate_event", "" ) ).toBe( "login" );
				}
				setup();
				local.evento = execute( event = "Categorias.index", renderResults = false );
				expect( local.evento.getValue( "relocate_event", "" ) ).toBe( "login" );
			} );

			it( "exibe login e rejeita POST sem CSRF ou com campos inválidos", function() {
				local.evento = get( route = "/login" );
				expect( local.evento.getCurrentView() ).toBe( "autenticacao/login" );
				local.token = local.evento.getPrivateValue( "csrfToken" );
				setup();
				local.evento = post( route = "/login" );
				expect( local.evento.getStatusCode() ).toBe( 403 );
				setup();
				local.evento = post( route = "/login", params = { csrfToken : local.token, txEmail : [], txSenha : {} } );
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

			it( "cadastra, autentica, protege a sessão e encerra o acesso", function() {
				transaction {
					try {
						local.email = lCase( createUUID() ) & "@example.invalid";
						local.dto = getWireBox().getInstance( "UsuarioDTO" );
						local.dto.setNmUsuario( "Usuário de teste" );
						local.dto.setTxEmail( uCase( local.email ) );
						local.dto.setTxSenha( "SenhaTeste123!" );
						local.dto.setTxConfirmacaoSenha( "SenhaTeste123!" );
						local.service = getWireBox().getInstance( "UsuarioService" );
						local.service.cadastrar( local.dto );
						local.dados = getWireBox().getInstance( "repositories.UsuarioRepository" ).obterPorEmail( local.email );
						expect( local.dados.tx_email ).toBe( local.email );
						expect( local.dados.tx_senha_hash ).notToInclude( "SenhaTeste123!" );
						expect( function() { service.cadastrar( dto ); } ).toThrow( "UsuarioDuplicado" );
						expect( local.service.isValidCredentials( local.email, "SenhaErrada123!" ) ).toBeFalse();
						expect( local.service.isValidCredentials( "ausente-" & local.email, "SenhaTeste123!" ) ).toBeFalse();
						local.token = csrfGenerateToken( "autenticacao" );
						local.evento = post( route = "/login", params = { csrfToken : local.token, txEmail : local.email, txSenha : "SenhaErrada123!" } );
						expect( local.evento.getStatusCode() ).toBe( 401 );
						expect( local.evento.getRenderedContent() ).notToInclude( "SenhaErrada123!" );
						setup();
						local.evento = post( route = "/login", params = { csrfToken : local.token, txEmail : local.email, txSenha : "SenhaTeste123!" }, renderResults = false );
						expect( local.evento.getValue( "relocate_URI", "" ) ).toBe( "/bem-vindo" );
						expect( getWireBox().getInstance( "authenticationService@cbauth" ).isLoggedIn() ).toBeTrue();
						setup();
						local.evento = get( route = "/bem-vindo" );
						expect( local.evento.getCurrentView() ).toBe( "autenticacao/boasVindas" );
						expect( local.evento.getRenderedContent() ).toInclude( "Bem-vindo(a), " & encodeForHTML( "Usuário de teste" ) );
						setup();
						local.evento = get( route = "/categorias" );
						expect( local.evento.getCurrentView() ).toBe( "categorias/index" );
						setup();
						local.evento = get( route = "/cadastro" );
						expect( local.evento.getCurrentView() ).toBe( "autenticacao/cadastro" );
						local.token = local.evento.getPrivateValue( "csrfToken" );
						setup();
						local.evento = post( route = "/cadastro", params = { nmUsuario : "Sem token" } );
						expect( local.evento.getStatusCode() ).toBe( 403 );
						setup();
						local.evento = post( route = "/cadastro", params = { csrfToken : local.token, nmUsuario : "Novo usuário", txEmail : "novo-" & local.email, txSenha : "NovaSenha12345!", txConfirmacaoSenha : "NovaSenha12345!" }, renderResults = false );
						expect( local.evento.getValue( "relocate_URI", "" ) ).toBe( "/cadastro" );
						expect( getWireBox().getInstance( "authenticationService@cbauth" ).getUser().getTxEmail() ).toBe( local.email );
						setup();
						local.evento = post( route = "/logout" );
						expect( local.evento.getStatusCode() ).toBe( 403 );
						setup();
						post( route = "/logout", params = { csrfToken : local.token }, renderResults = false );
						expect( getWireBox().getInstance( "authenticationService@cbauth" ).isLoggedIn() ).toBeFalse();
						setup();
						local.evento = get( route = "/categorias", renderResults = false );
						expect( local.evento.getValue( "relocate_event", "" ) ).toBe( "login" );
					} finally {
						getWireBox().getInstance( "authenticationService@cbauth" ).logout( quiet = true );
						transaction action="rollback";
					}
				}
			} );
		} );
	}

}
