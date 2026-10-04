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
		route( "/login" ).withHandler( "Autenticacao" ).toAction( { GET : "login", POST : "entrar" } );
		route( "/cadastro" ).withHandler( "Autenticacao" ).toAction( { GET : "cadastro", POST : "criar" } );
		get( "/bem-vindo", "Autenticacao.boasVindas" );
		post( "/logout", "Autenticacao.sair" );
		post( "/autenticacao/renovar", "Autenticacao.renovar" );
		get( "/autenticacao/token", "Autenticacao.token" );
		route( "/categorias/adicionar" ).withHandler( "Categorias" ).toAction( { GET : "adicionar", POST : "criar" } );
		route( "/categorias/:cdCategoria/editar" ).withHandler( "Categorias" ).toAction( { GET : "editar", POST : "salvar" } );
		route( "/categorias/:cdCategoria/inativar" ).withHandler( "Categorias" ).toAction( { GET : "confirmarInativacao", POST : "inativar" } );
		// O handler aceita somente PUT e responde 405 em JSON para outros métodos.
		route( "/categorias/:cdCategoria/reativar", "Categorias.reativar" );

		get( "/categorias", "Categorias.index" );

		post( "/api/fornecedores/indicacao", "api.Fornecedores.indicacao" );
		post( "/api/fornecedores/:cdFornecedor/testemunho", "api.Fornecedores.postTestemunho" );
		get( "/api/fornecedores", "api.Fornecedores.getFornecedores" );

		get( "/fornecedores/indicar", "Fornecedores.indicar" );
		route( "/fornecedores/adicionar" ).withHandler( "Fornecedores" ).toAction( { GET : "addFornecedor", POST : "criar" } );
		get( "/fornecedores/aprovacao", "Fornecedores.aprovacao" );
		post( "/fornecedores/:cdFornecedor/aprovar", "Fornecedores.aprovarFornecedor" );
		post( "/fornecedores/:cdFornecedor/excluir", "Fornecedores.excluirFornecedor" );
		get( "/fornecedores/:cdFornecedor", "Fornecedores.getFornecedor" );

		// Conventions-Based Routing
		route( ":handler/:action?" ).end();
	}

}
