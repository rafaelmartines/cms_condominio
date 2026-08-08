component extends="coldbox.system.RestHandler" {

	remote any function getFornecedores( event, rc, prc ) renderData="json" {
		param arguments.rc.nmFornecedor = arguments.rc[ "filtroNome" ] ?: "";
		param arguments.rc.cdCategoria  = arguments.rc[ "filtroCategoria" ] ?: "";
		param arguments.rc.orderColumn  = arguments.rc[ "order[0][column]" ] ?: "0";
		param arguments.rc.orderDir     = arguments.rc[ "order[0][dir]" ] ?: "asc";

		local.fornecedoresFiltroDTO = populateModel( "FornecedoresFiltroDTO" );

		return getInstance( "FornecedoresService" ).getFornecedores( local.fornecedoresFiltroDTO );
	}

	remote any function postTestemunho( event, rc, prc ) renderData="json" {
		local.corpo = deserializeJSON( arguments.event.getHttpContent() );

		local.testemunhoDTO = populateModel( model = "TestemunhoDTO", memento = local.corpo );
		local.testemunhoDTO.setCdFornecedor( arguments.rc.cdFornecedor );

		return getInstance( "FornecedoresService" ).postTestemunho( local.testemunhoDTO );
	}

}
