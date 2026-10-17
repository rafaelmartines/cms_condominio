component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {
	function run() {
		describe( "Indicação HTTP somente no banco", function() {
			beforeEach( function() {
				setup();
				variables.service = prepareMock( getWireBox().getInstance( "FornecedoresService" ) );
				variables.resendOriginal = variables.service.$getProperty( "resend", "variables" );
				variables.resend = createStub().$( "enviarEmail" ).$throws( type = "ResendException", message = "Envio proibido neste teste" );
				variables.service.$property( "resend", "variables", variables.resend );
				variables.interceptor = prepareMock( getController().getInterceptorService().getInterceptor( "NotificacaoErros" ) );
				variables.notificadorOriginal = variables.interceptor.$getProperty( "erroService", "variables" );
				variables.notificador = prepareMock( new app.models.ErroService() );
				variables.notificador.$property( "resend", "variables", variables.resend );
				variables.notificador.$property( "log", "variables", createStub().$( "error" ) );
				variables.interceptor.$property( "erroService", "variables", variables.notificador );
			} );
			afterEach( function() {
				variables.service.$property( "resend", "variables", variables.resendOriginal );
				variables.interceptor.$property( "erroService", "variables", variables.notificadorOriginal );
			} );

			it( "retorna 201 e persiste Aguardando mesmo com tentativa de escolher outro status", function() {
				transaction {
					try {
						local.categoria = getWireBox().getInstance( "Categoria" ).create( { txCategoria : "Indicação HTTP teste", inAtivo : true } ).getCdCategoria();
						local.dados = dadosValidos( local.categoria );
						local.dados.statusId = 1;
						// Mesmo formato do formulário: IDs como texto e Instagram opcional nulo.
						local.dados.categorias = [ toString( local.categoria ) ];
						local.dados.txInstagram = javacast( "null", "" );
						local.resultado = post( route = "/api/fornecedores/indicacao", body = serializeJSON( local.dados ), headers = { "Content-Type" : "application/json" } );
						expect( local.resultado.getStatusCode() ).toBe( 201 );
						expect( local.resultado.getRenderedContent() ).toInclude( "aguardando aprovação" );
						local.registros = getWireBox().getInstance( "Fornecedor" ).where( "nmFornecedor", local.dados.nmFornecedor ).get();
						expect( local.registros ).toHaveLength( 1 );
						expect( local.registros[ 1 ].status().first().getDescricao() ).toBe( "Aguardando" );
						expect( variables.resend.$count( "enviarEmail" ) ).toBe( 0 );
					} finally { transaction action="rollback"; }
				}
			} );

			it( "retorna 400 para JSON malformado ou diferente de objeto sem e-mail", function() {
				for ( local.corpo in [ "{", "[]", '"texto"', "null" ] ) {
					setup();
					local.resultado = post( route = "/api/fornecedores/indicacao", body = local.corpo, headers = { "Content-Type" : "application/json" } );
					expect( local.resultado.getStatusCode() ).toBe( 400 );
				}
				expect( variables.resend.$count( "enviarEmail" ) ).toBe( 0 );
			} );

			it( "retorna 422 para dados inválidos sem e-mail", function() {
				local.dados = dadosValidos( 1 );
				local.dados.nrApartamento = "0";
				local.resultado = post( route = "/api/fornecedores/indicacao", body = serializeJSON( local.dados ), headers = { "Content-Type" : "application/json" } );
				expect( local.resultado.getStatusCode() ).toBe( 422 );
				expect( local.resultado.getRenderedContent() ).toInclude( "apartamento válido" );
				expect( variables.resend.$count( "enviarEmail" ) ).toBe( 0 );
			} );

			it( "retorna 422 para tipos inválidos antes dos setters", function() {
				for ( local.campo in [ "nmFornecedor", "nrNota", "categorias", "txInstagram" ] ) {
					setup();
					local.dados = dadosValidos( 1 );
					local.dados[ local.campo ] = {};
					local.resultado = post( route = "/api/fornecedores/indicacao", body = serializeJSON( local.dados ), headers = { "Content-Type" : "application/json" } );
					expect( local.resultado.getStatusCode() ).toBe( 422 );
				}
				expect( variables.resend.$count( "enviarEmail" ) ).toBe( 0 );
			} );

			it( "retorna 500 para falha inesperada sem expor detalhes nem enviar e-mail", function() {
				local.original = variables.service.$getProperty( "fornecedoresRepository", "variables" );
				variables.service.$property( "fornecedoresRepository", "variables", createStub().$( "addIndicacao" ).$throws( type = "Database", message = "segredo do banco" ) );
				try {
					local.resultado = post( route = "/api/fornecedores/indicacao", body = serializeJSON( dadosValidos( 1 ) ), headers = { "Content-Type" : "application/json" } );
					expect( local.resultado.getStatusCode() ).toBe( 500 );
					expect( local.resultado.getRenderedContent() ).toInclude( "Não foi possível registrar" );
					expect( local.resultado.getRenderedContent() ).notToInclude( "segredo do banco" );
					expect( variables.resend.$count( "enviarEmail" ) ).toBe( 0 );
				} finally {
					variables.service.$property( "fornecedoresRepository", "variables", local.original );
				}
			} );

			it( "rota inexistente retorna 404 sem notificação", function() {
				local.resultado = get( route = "/rota-inexistente/indicar" );
				expect( local.resultado.getStatusCode() ).toBe( 404 );
				expect( variables.resend.$count( "enviarEmail" ) ).toBe( 0 );
			} );
		} );
	}

	private struct function dadosValidos( required numeric categoria ) {
		return { nmFornecedor : "Indicação " & createUUID(), categorias : [ arguments.categoria ],
			nrWhatsapp : "+55 (11) 99999-9999", txInstagram : "", nmIndicador : "Morador teste",
			nrApartamento : "101", txMotivo : "Bom atendimento" };
	}
}
