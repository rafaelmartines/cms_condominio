component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {
	function run() {
		describe( "Validação e envio pela Resend sem acesso externo", function() {
			beforeEach( function() {
				setup();
				variables.config = { from : "CMS <avisos@example.org>", to : "destino@example.org", dominio : "example.org", key : "chave-simulada", uri : "https://api.resend.com/emails" };
				variables.payload = { subject : "Assunto privado", text : "Conteúdo privado" };
				variables.cliente = prepareMock( new app.models.integrations.Resend() );
				variables.logger = createStub().$( "error" );
				variables.cliente.$property( "log", "variables", variables.logger );
				variables.cliente.$( "obterConfiguracao", variables.config );
				variables.cliente.$( "executarRequisicao", { statusCode : "200 OK" } );
			} );

			it( "normaliza destinatário como array sem alterar o payload original", function() {
				expect( variables.cliente.enviarEmail( variables.payload ) ).toBeTrue();
				local.enviado = variables.cliente.$callLog().executarRequisicao[ 1 ].payload;
				expect( local.enviado.to ).toBe( [ "destino@example.org" ] );
				expect( local.enviado.from ).toBe( variables.config.from );
				expect( structKeyExists( variables.payload, "from" ) ).toBeFalse();
			} );

			it( "substitui endereços inválidos pelos configurados", function() {
				variables.payload.from = "inválido";
				variables.payload.to = [ "inválido", "outro@example.org" ];
				variables.payload.reply_to = "inválido";
				variables.cliente.enviarEmail( variables.payload );
				local.enviado = variables.cliente.$callLog().executarRequisicao[ 1 ].payload;
				expect( local.enviado.from ).toBe( variables.config.from );
				expect( local.enviado.to ).toBe( [ "destino@example.org", "outro@example.org" ] );
				expect( local.enviado.reply_to ).toBe( [ "destino@example.org" ] );
			} );

			it( "bloqueia campos obrigatórios inválidos antes de qualquer requisição", function() {
				for ( local.invalido in [ {}, { subject : " ", text : "corpo" }, { subject : "Assunto" }, { subject : "Assunto", html : " ", text : " " }, { subject : [], text : "corpo" }, { subject : "Assunto", text : {} }, { subject : "Assunto", text : "corpo", to : {} } ] ) {
					local.dados = local.invalido;
					expect( function() { variables.cliente.enviarEmail( dados ); } ).toThrow( "ResendException" );
				}
				expect( variables.cliente.$count( "executarRequisicao" ) ).toBe( 0 );
			} );

			it( "bloqueia configuração inválida ou remetente fora do domínio autorizado", function() {
				for ( local.campo in [ "from", "to", "dominio", "key", "uri" ] ) {
					local.configInvalida = duplicate( variables.config );
					local.configInvalida[ local.campo ] = "";
					variables.cliente.$( "obterConfiguracao", local.configInvalida );
					expect( function() { variables.cliente.enviarEmail( variables.payload ); } ).toThrow( "ResendException" );
				}
				expect( variables.cliente.$count( "executarRequisicao" ) ).toBe( 0 );
			} );

			it( "bloqueia domínio divergente e cabeçalhos injetados", function() {
				variables.config.dominio = "outro.example.org";
				variables.cliente.$( "obterConfiguracao", variables.config );
				expect( function() { variables.cliente.enviarEmail( variables.payload ); } ).toThrow( "ResendException" );
				variables.config.dominio = "example.org";
				variables.config.from = "avisos@example.org" & chr( 13 ) & chr( 10 ) & "Bcc: outro@example.org";
				variables.cliente.$( "obterConfiguracao", variables.config );
				expect( function() { variables.cliente.enviarEmail( variables.payload ); } ).toThrow( "ResendException" );
				expect( variables.cliente.$count( "executarRequisicao" ) ).toBe( 0 );
			} );

			it( "recusa lista vazia ou mais de 50 destinatários", function() {
				variables.payload.to = [];
				expect( function() { variables.cliente.enviarEmail( variables.payload ); } ).toThrow( "ResendException" );
				for ( local.i = 1; local.i LTE 51; local.i++ ) arrayAppend( variables.payload.to, "destino@example.org" );
				expect( function() { variables.cliente.enviarEmail( variables.payload ); } ).toThrow( "ResendException" );
				expect( variables.cliente.$count( "executarRequisicao" ) ).toBe( 0 );
			} );

			it( "explica a restrição do domínio de testes quando a API retorna 403", function() {
				variables.config.from = "onboarding@resend.dev";
				variables.config.dominio = "resend.dev";
				variables.cliente.$( "obterConfiguracao", variables.config );
				variables.cliente.$( "executarRequisicao", { statusCode : "403 Forbidden" } );
				expect( function() { variables.cliente.enviarEmail( variables.payload ); } ).toThrow( "ResendException", "", "própria conta" );
				expect( variables.cliente.$count( "executarRequisicao" ) ).toBe( 1 );
			} );

			it( "aceita conteúdo HTML e resposta 201", function() {
				variables.cliente.$( "executarRequisicao", { statusCode : "201 Created" } );
				expect( variables.cliente.enviarEmail( { subject : "Assunto", html : "<p>Mensagem</p>" } ) ).toBeTrue();
			} );

			it( "registra payload 422 sem dados pessoais e não reenvia", function() {
				variables.cliente.$( "executarRequisicao", { statusCode : "422 Unprocessable Entity", fileContent : "resposta privada" } );
				expect( function() { variables.cliente.enviarEmail( variables.payload ); } ).toThrow( "ResendException", "", "dados inválidos" );
				expect( variables.cliente.$count( "executarRequisicao" ) ).toBe( 1 );
				local.registro = serializeJSON( variables.logger.$callLog().error );
				expect( local.registro ).toInclude( "422" );
				for ( local.segredo in [ "Assunto privado", "Conteúdo privado", "example.org", "chave-simulada", "resposta privada" ] ) {
					expect( local.registro ).notToInclude( local.segredo );
				}
			} );

			it( "não reenvia em erro HTTP ou falha de comunicação", function() {
				variables.cliente.$( "executarRequisicao", { statusCode : "500 Internal Server Error" } );
				expect( function() { variables.cliente.enviarEmail( variables.payload ); } ).toThrow( "ResendException" );
				expect( variables.cliente.$count( "executarRequisicao" ) ).toBe( 1 );
				variables.cliente.$( "executarRequisicao" ).$throws( type = "IOException", message = "Timeout" );
				expect( function() { variables.cliente.enviarEmail( variables.payload ); } ).toThrow( "ResendException" );
				expect( variables.cliente.$count( "executarRequisicao" ) ).toBe( 1 );
			} );

			it( "API de testemunho informa a falha e impede notificação recursiva", function() {
				local.servico = createStub().$( "postIndicacao" ).$throws( type = "ResendException", message = "Dados inválidos. Não houve reenvio automático." );
				local.servico.$( "postTestemunho" ).$throws( type = "ResendException", message = "Dados inválidos. Não houve reenvio automático." );
				local.handler = prepareMock( new app.handlers.api.Fornecedores() );
				local.handler.$( "getInstance", local.servico );
				local.handler.$( "populateModel", createStub().$( "setCdFornecedor" ) );
				for ( local.acao in [ "postTestemunho" ] ) {
					setup();
					local.evento = prepareMock( getRequestContext() ).$( "getHttpContent", "{}" );
					local.prc = local.evento.getPrivateCollection();
					invoke( local.handler, local.acao, { event : local.evento, rc : { cdFornecedor : 1 }, prc : local.prc } );
					expect( local.evento.getRenderData().statusCode ).toBe( 502 );
					expect( local.evento.getRenderData().data.message ).toInclude( "Não houve reenvio" );
					expect( local.prc.erroEmailProcessado ).toBeTrue();
					local.notificador = prepareMock( new app.models.ErroService() );
					local.notificador.$property( "resend", "variables", variables.cliente );
					local.notificador.notificar( local.evento, 502 );
					expect( variables.cliente.$count( "executarRequisicao" ) ).toBe( 0 );
				}
			} );
		} );
	}
}
