component extends="coldbox.system.RestHandler" {

	remote any function getFornecedores( event, rc, prc ) renderData="json" {
		param arguments.rc.nmFornecedor = arguments.rc[ "search[value]" ] ?: "";

		local.fornecedoresFiltroDTO = populateModel( "FornecedoresFiltroDTO" );

		return getInstance( "FornecedoresService" ).getFornecedores( local.fornecedoresFiltroDTO );
	}

}
