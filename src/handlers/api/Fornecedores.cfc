component extends="coldbox.system.RestHandler" {

	remote any function getFornecedores( event, rc, prc ) renderData="json" {
		return getInstance( "FornecedoresService" ).getFornecedores();
	}

}
