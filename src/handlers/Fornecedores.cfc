component extends="coldbox.system.EventHandler" {

	public any function getFornecedor( event, rc, prc ) {
		arguments.prc.fornecedor = getInstance( "FornecedoresService" ).getFornecedor( arguments.rc.cdFornecedor );
		arguments.event.setView( "fornecedores/fornecedor" );
	}

}
