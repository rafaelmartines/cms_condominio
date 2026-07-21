component extends="coldbox.system.EventHandler" {

	function index( event, rc, prc ) {
		param arguments.rc.nmFornecedor = arguments.rc[ "search[value]" ] ?: "";
		param arguments.rc.orderColumn  = arguments.rc[ "order[0][column]" ] ?: "0";
		param arguments.rc.orderDir     = arguments.rc[ "order[0][dir]" ] ?: "asc";

		local.fornecedoresFiltroDTO = populateModel( "FornecedoresFiltroDTO" );
		arguments.prc.fornecedores  = getInstance( "FornecedoresService" ).getFornecedores( local.fornecedoresFiltroDTO );

		arguments.event.setView( "main/index" );
	}

	/**
	 * Produce some restfulf data
	 */
	function data( event, rc, prc ) {
		return [
			{ "id" : createUUID(), "name" : "Luis" },
			{ "id" : createUUID(), "name" : "Joe" },
			{ "id" : createUUID(), "name" : "Bob" },
			{
				"id"   : createUUID(),
				"name" : "Darth"
			}
		];
	}

	/**
	 * Relocation example
	 */
	function doSomething( event, rc, prc ) {
		relocate( "main.index" );
	}

	/**
	 * --------------------------------------------------------------------------
	 * Implicit Actions
	 * --------------------------------------------------------------------------
	 * All the implicit actions below MUST be declared in the config/Coldbox.cfc in order to fire.
	 * https://coldbox.ortusbooks.com/getting-started/configuration/coldbox.cfc/configuration-directives/coldbox#implicit-event-settings
	 */

	function onAppInit( event, rc, prc ) {
	}

	function onRequestStart( event, rc, prc ) {
		application.environment = getEnv( "ENVIRONMENT" );
	}

	function onRequestEnd( event, rc, prc ) {
	}

	function onSessionStart( event, rc, prc ) {
	}

	function onSessionEnd( event, rc, prc ) {
		var sessionScope     = event.getValue( "sessionReference" );
		var applicationScope = event.getValue( "applicationReference" );
	}

	function onException( event, rc, prc ) {
		event.setHTTPHeader( statusCode = 500 );
		// Grab Exception From private request collection, placed by ColdBox Exception Handling
		var exception = prc.exception;
		// Place exception handler below:
	}

}
