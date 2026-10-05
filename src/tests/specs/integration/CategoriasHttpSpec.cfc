component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {
	function run() {
		describe( "Reativação de categorias por HTTP real", function() {
			beforeEach( function() { setup(); } );

			it( "autentica e reativa com PUT, retornando JSON e persistindo a situação", function() {
				local.usuario = getWireBox().getInstance( "Usuario" ).create( {
					nmUsuario : "Teste HTTP de categorias",
					txEmail : lCase( createUUID() ) & "@example.invalid",
					txSenhaHash : getWireBox().getInstance( "security.SenhaService" ).gerarHash( "SenhaTesteHttp123!" )
				} );
				local.categoriaId = 0;
				local.tokens = {};
				local.baseUrl = "http://127.0.0.1:#cgi.server_port#";
				try {
					// Sem transação externa: a requisição HTTP usa outra conexão com o banco.
					local.categoria = getWireBox().getInstance( "Categoria" ).create( {
						txCategoria : "Categoria HTTP " & createUUID(), inAtivo : false
					} );
					local.categoriaId = local.categoria.getCdCategoria();
					cfhttp( method = "POST", url = local.baseUrl & "/auth", result = "local.login", timeout = 15, redirect = false ) {
						cfhttpparam( type = "header", name = "Accept", value = "application/json" );
						cfhttpparam( type = "header", name = "Content-Type", value = "application/json" );
						cfhttpparam( type = "body", value = serializeJSON( { txEmail : local.usuario.getTxEmail(), txSenha : "SenhaTesteHttp123!" } ) );
					}
					expect( val( local.login.statusCode ) ).toBe( 200 );
					local.tokens = deserializeJSON( local.login.fileContent );
					// O mesmo contrato JSON enviado por autenticacao.js, incluindo entradas inválidas.
					for ( local.caso in [
						{ corpo : serializeJSON( { txEmail : local.usuario.getTxEmail(), txSenha : "SenhaErradaHttp123!" } ), status : 401 },
						{ corpo : serializeJSON( { txEmail : "inexistente-" & local.usuario.getTxEmail(), txSenha : "SenhaTesteHttp123!" } ), status : 401 },
						{ corpo : serializeJSON( { txEmail : [], txSenha : {} } ), status : 422 },
						{ corpo : "{}", status : 422 },
						{ corpo : "{", status : 400 },
						{ corpo : "[]", status : 400 }
					] ) {
						cfhttp( method = "POST", url = local.baseUrl & "/auth", result = "local.falhaLogin", timeout = 15, redirect = false ) {
							cfhttpparam( type = "header", name = "Accept", value = "application/json" );
							cfhttpparam( type = "header", name = "Content-Type", value = "application/json" );
							cfhttpparam( type = "body", value = local.caso.corpo );
						}
						expect( val( local.falhaLogin.statusCode ) ).toBe( local.caso.status );
						expect( local.falhaLogin.responseHeader[ "Content-Type" ] ).toInclude( "application/json" );
						local.erroLogin = deserializeJSON( local.falhaLogin.fileContent );
						expect( len( local.erroLogin.erro ) GT 0 ).toBeTrue();
						expect( structKeyExists( local.erroLogin, "access_token" ) ).toBeFalse();
					}
					for ( local.tentativa in [ 1, 2 ] ) {
						cfhttp( method = "PUT", url = local.baseUrl & "/categorias/#local.categoriaId#/reativar", result = "local.resposta", timeout = 15, redirect = false ) {
							cfhttpparam( type = "header", name = "Accept", value = "application/json" );
							cfhttpparam( type = "header", name = "Authorization", value = "Bearer " & local.tokens.access_token );
						}
						expect( val( local.resposta.statusCode ) ).toBe( 200 );
						expect( local.resposta.responseHeader[ "Content-Type" ] ).toInclude( "application/json" );
						expect( local.resposta.fileContent ).notToInclude( "Invalid HTTP Method" );
						local.dados = deserializeJSON( local.resposta.fileContent );
						expect( local.dados.cdCategoria ).toBe( local.categoriaId );
						expect( local.dados.txCategoria ).toBe( local.categoria.getTxCategoria() );
						expect( local.dados.inAtivo ).toBeTrue();
						expect( getWireBox().getInstance( "CategoriaService" ).obterCategoria( local.categoriaId ).inAtivo ).toBeTrue();
					}
				} finally {
					try {
						if ( structKeyExists( local.tokens, "refresh_token" ) ) {
							cfhttp( method = "POST", url = local.baseUrl & "/logout", result = "local.logout", timeout = 15 ) {
								cfhttpparam( type = "header", name = "Authorization", value = "Bearer " & local.tokens.refresh_token );
								cfhttpparam( type = "header", name = "Accept", value = "application/json" );
							}
						}
					} finally {
						if ( local.categoriaId GT 0 ) getWireBox().getInstance( "Categoria" ).findOrFail( local.categoriaId ).delete();
						local.usuario.delete();
					}
				}
			} );
		} );
	}
}
