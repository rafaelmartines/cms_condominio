component extends="coldbox.system.Interceptor" {
	property name="erroService" inject="ErroService";

	function configure() {}

	function onException( event, interceptData, rc, prc ) {
		variables.erroService.notificar( arguments.event, 500, arguments.interceptData.exception ?: {} );
	}

	function postProcess( event, interceptData, rc, prc ) {
		local.status = arguments.event.getStatusCode();
		local.renderData = arguments.event.getRenderData();
		if ( structKeyExists( local.renderData, "statusCode" ) ) local.status = max( local.status, local.renderData.statusCode );
		if ( structKeyExists( arguments.prc, "response" ) ) local.status = max( local.status, arguments.prc.response.getStatusCode() );
		if ( local.status GTE 400 ) {
			variables.erroService.notificar( arguments.event, local.status, arguments.prc.erroNotificacao ?: {} );
		}
	}
}
