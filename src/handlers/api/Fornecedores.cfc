component extends="coldbox.system.RestHandler" {

	remote any function getFornecedores( event, rc, prc ) renderData="json" {
		param arguments.rc.nmFornecedor = arguments.rc[ "search[value]" ] ?: "";
		param arguments.rc.orderColumn  = arguments.rc[ "order[0][column]" ] ?: "0";
		param arguments.rc.orderDir     = arguments.rc[ "order[0][dir]" ] ?: "asc";

		local.fornecedoresFiltroDTO = populateModel( "FornecedoresFiltroDTO" );

		return getInstance( "FornecedoresService" ).getFornecedores( local.fornecedoresFiltroDTO );
	}

}
