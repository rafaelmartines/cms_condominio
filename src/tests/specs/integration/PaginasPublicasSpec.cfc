component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {
	function run() {
		describe( "Página inicial e listagem pública de fornecedores", function() {
			beforeEach( function() {
				setup();
				prepareMock( getWireBox().getInstance( "ErroService" ) ).$( "notificar" );
			} );

			it( "exibe atalhos na página inicial sem carregar a listagem", function() {
				local.event = get( route = "/" );
				expect( local.event.getStatusCode() ).toBe( 200 );
				expect( local.event.getCurrentView() ).toBe( "main/index" );
				expect( local.event.getRenderedContent() ).toInclude( "Principais Serviços" );
				expect( local.event.getRenderedContent() ).toInclude( 'href="/fornecedores"' );
				expect( local.event.getRenderedContent() ).toInclude( 'href="/faq"' );
				expect( local.event.getRenderedContent() ).toInclude( 'href="https://uclass.com.br/bn/vbstar/"' );
				expect( local.event.getRenderedContent() ).notToInclude( 'id="minhaTabela"' );
				expect( local.event.getRenderedContent() ).notToInclude( 'id="formFiltroFornecedores"' );
				expect( local.event.privateValueExists( "categorias" ) ).toBeFalse();
			} );

			it( "abre a listagem sem autenticação e mantém filtros e carregamento pela API", function() {
				local.event = get( route = "/fornecedores" );
				expect( local.event.getStatusCode() ).toBe( 200 );
				expect( local.event.getCurrentView() ).toBe( "fornecedores/index" );
				expect( local.event.getRenderedContent() ).toInclude( 'id="minhaTabela"' );
				expect( local.event.getRenderedContent() ).toInclude( 'id="filtroNome"' );
				expect( local.event.getRenderedContent() ).toInclude( 'id="filtroCategoria"' );
				expect( local.event.getPrivateValue( "scripts" ) ).toInclude( "/api/fornecedores" );
				expect( local.event.getRenderedContent() ).toInclude( "Voltar ao início" );
			} );
		} );
	}
}
