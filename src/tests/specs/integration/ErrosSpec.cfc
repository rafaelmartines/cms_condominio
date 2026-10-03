component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {
	function run() {
		describe( "Notificação de erros com logs", function() {
			beforeEach( function() {
				setup();
				variables.enviados = [];
				variables.resend = createStub().$( "enviarEmail" ).$callback( function( corpoEmail ) {
					arrayAppend( variables.enviados, arguments.corpoEmail );
					return true;
				} );
				variables.servico = prepareMock( new app.models.ErroService() );
				variables.servico.$property( "resend", "variables", variables.resend );
				variables.servico.$property( "log", "variables", createStub().$( "error" ) );
				variables.evento = getRequestContext();
			} );

			it( "envia log em Base64 por enviarEmail sem dados sensíveis", function() {
				variables.servico.notificar( variables.evento, 500, {
					type : "Database", message : "senha-secreta", detail : "Bearer segredo",
					tagContext : [ { template : "/app/models/Teste.cfc", line : 12, codePrintPlain : "token-secreto" } ]
				} );
				expect( arrayLen( variables.enviados ) ).toBe( 1 );
				local.email = variables.enviados[ 1 ];
				expect( local.email.subject ).toInclude( "500" );
				local.log = charsetEncode( toBinary( local.email.attachments[ 1 ].content ), "UTF-8" );
				expect( local.log ).toInclude( "Database" );
				expect( local.log ).toInclude( "Teste.cfc" );
				expect( local.log ).notToInclude( "senha-secreta" );
				expect( local.log ).notToInclude( "segredo" );
				expect( local.email.attachments[ 1 ].filename ).toInclude( ".log" );
			} );

			it( "notifica somente uma vez por requisição", function() {
				variables.servico.notificar( variables.evento, 500 );
				variables.servico.notificar( variables.evento, 500 );
				expect( arrayLen( variables.enviados ) ).toBe( 1 );
			} );

			it( "falha do Resend não propaga nem provoca novo envio", function() {
				variables.resend.$( "enviarEmail" ).$callback( function( corpoEmail ) { throw( type = "ResendException", message = "Falha simulada" ); } );
				variables.servico.notificar( variables.evento, 500 );
				variables.servico.notificar( variables.evento, 500 );
				expect( variables.resend.$count( "enviarEmail" ) ).toBe( 1 );
			} );

			it( "interceptor cobre respostas 401 e 422 sem exceção", function() {
				local.interceptor = prepareMock( new app.interceptors.NotificacaoErros() );
				local.interceptor.$property( "erroService", "variables", variables.servico );
				variables.evento.renderData( type = "json", statusCode = 422, data = { erro : "Inválido" } );
				local.interceptor.postProcess( variables.evento, {}, {}, variables.evento.getPrivateCollection() );
				expect( arrayLen( variables.enviados ) ).toBe( 1 );
				expect( variables.enviados[ 1 ].subject ).toInclude( "422" );
				structDelete( variables.evento.getPrivateCollection(), "erroEmailProcessado" );
				variables.evento.renderData( type = "json", statusCode = 401, data = {} );
				local.interceptor.postProcess( variables.evento, {}, {}, variables.evento.getPrivateCollection() );
				expect( variables.enviados[ 2 ].subject ).toInclude( "401" );
			} );

			it( "resposta bem sucedida não envia e-mail", function() {
				local.interceptor = prepareMock( new app.interceptors.NotificacaoErros() );
				local.interceptor.$property( "erroService", "variables", variables.servico );
				local.interceptor.postProcess( variables.evento, {}, {}, variables.evento.getPrivateCollection() );
				expect( arrayLen( variables.enviados ) ).toBe( 0 );
			} );

			it( "interceptor registrado notifica erro real de formulário sem mudar a resposta", function() {
				local.interceptor = prepareMock( getController().getInterceptorService().getInterceptor( "NotificacaoErros" ) );
				local.original = local.interceptor.$getProperty( "erroService", "variables" );
				local.interceptor.$property( "erroService", "variables", variables.servico );
				try {
					local.resultado = post( route = "/login", params = { txEmail : "inválido", txSenha : "" } );
					expect( local.resultado.getStatusCode() ).toBe( 422 );
					expect( arrayLen( variables.enviados ) ).toBe( 1 );
					expect( variables.enviados[ 1 ].subject ).toInclude( "422" );
				} finally {
					local.interceptor.$property( "erroService", "variables", local.original );
				}
			} );

			it( "exceção global envia 500 e preserva o status original", function() {
				local.interceptor = prepareMock( new app.interceptors.NotificacaoErros() );
				local.interceptor.$property( "erroService", "variables", variables.servico );
				local.interceptor.onException( variables.evento, { exception : { type : "FalhaSimulada" } }, {}, variables.evento.getPrivateCollection() );
				expect( variables.enviados[ 1 ].subject ).toInclude( "500" );
				expect( variables.evento.getStatusCode() ).toBe( 200 );
			} );
		} );
	}
}
