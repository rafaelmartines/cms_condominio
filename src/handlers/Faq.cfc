component extends="coldbox.system.EventHandler" {
	property name="faqService" inject="FaqService";
	this.allowedMethods = { index : "GET" };

	public void function index( event, rc, prc ) {
		arguments.prc.titulo = "Perguntas frequentes";
		arguments.prc.busca = arguments.rc.busca ?: "";
		arguments.prc.perguntas = variables.faqService.listarPublicas( arguments.prc.busca );
		arguments.event.setView( "faq/index" );
	}

	public void function onError( event, rc, prc, faultAction, exception, eventArguments ) {
		arguments.prc.erroNotificacao = arguments.exception;
		arguments.prc.titulo = "Perguntas frequentes";
		arguments.prc.erro = "Não foi possível carregar as perguntas. Tente novamente em instantes.";
		local.status = 500;
		if ( arguments.exception.type EQ "FaqInvalido" ) {
			local.status = 422;
			arguments.prc.erro = arguments.exception.message;
		} else if ( arguments.exception.type EQ "InvalidHTTPMethod" ) {
			local.status = 405;
			arguments.prc.erro = "Use GET para consultar as perguntas frequentes.";
			arguments.event.setHTTPHeader( name = "Allow", value = "GET" );
		}
		arguments.event.setHTTPHeader( statusCode = local.status );
		arguments.event.setView( "faq/erro" );
	}
}
