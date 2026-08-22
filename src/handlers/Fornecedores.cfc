component extends="coldbox.system.EventHandler" {

	public any function getFornecedor( event, rc, prc ) {
		arguments.prc.fornecedor  = getInstance( "FornecedoresService" ).getFornecedor( arguments.rc.cdFornecedor );
		arguments.prc.titulo      = "Detalhes - #arguments.prc.fornecedor.nmFornecedor#";
		arguments.prc.comentarios = getInstance( "FornecedoresService" ).getComentariosPorFornecedor(
			arguments.rc.cdFornecedor
		);
		arguments.prc.media = getInstance( "FornecedoresService" ).getMedia( arguments.rc.cdFornecedor );
		arguments.event.setView( "fornecedores/fornecedor" );
	}

	public function addFornecedor( event, rc, prc ) {
		arguments.prc.categorias = getInstance( "CategoriaService" ).obterCategorias();
		arguments.prc.titulo     = "Adicionar Fornecedor";
		arguments.event.setView( "fornecedores/adicionar" );
	}

}
