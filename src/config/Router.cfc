/**
 * This is your application router.  From here you can controll all the incoming routes to your application.
 *
 * https://coldbox.ortusbooks.com/the-basics/routing
 */
component {

	function configure() {
		/**
		 * --------------------------------------------------------------------------
		 * App Routes
		 * --------------------------------------------------------------------------
		 * Here is where you can register the routes for your web application!
		 * Go get Funky!
		 */

		// A nice healthcheck route example
		// route( "/healthcheck", function( event, rc, prc ){
		// 	return "Ok!";
		// } );

		route( "/healthcheck", "api.Healthcheck.checkDatabase" );

		// A nice RESTFul Route example
		route( "/api/echo", function( event, rc, prc ) {
			return {
				"error" : false,
				"data"  : "Welcome to my awesome API!"
			};
		} );

		// @app_routes@
		post( "/api/fornecedores/:cdFornecedor/testemunho", "api.Fornecedores.postTestemunho" );
		get( "/api/fornecedores", "api.Fornecedores.getFornecedores" );

		get( "/fornecedores/:cdFornecedor", "Fornecedores.getFornecedor" );

		// Conventions-Based Routing
		route( ":handler/:action?" ).end();
	}

}
