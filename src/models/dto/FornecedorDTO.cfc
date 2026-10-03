component accessors="true" {
	property name="nmFornecedor" default="";
	property name="nmEmpresa" default="";
	property name="nrTelefone" default="";
	property name="txInstagram" default="";
	property name="categorias" default="";

	public struct function validar() {
		local.dados = {};
		for ( local.campo in [ "nmFornecedor", "nmEmpresa", "nrTelefone", "txInstagram" ] ) {
			if ( NOT isSimpleValue( variables[ local.campo ] ) ) invalido();
			local.dados[ local.campo ] = trim( variables[ local.campo ] );
		}
		if ( NOT len( local.dados.nmFornecedor ) OR len( local.dados.nmFornecedor ) GT 100 OR len( local.dados.nmEmpresa ) GT 150 ) {
			invalido( "Informe o nome do fornecedor e use até 100 caracteres para nome e 150 para empresa." );
		}
		if ( NOT reFind( "^[+0-9 ()-]+$", local.dados.nrTelefone ) ) invalido( "Informe um telefone válido." );
		local.dados.nrTelefone = reReplace( local.dados.nrTelefone, "[^0-9]", "", "all" );
		if ( NOT reFind( "^[1-9][0-9]{9,14}$", local.dados.nrTelefone ) ) invalido( "Informe de 10 a 15 dígitos no telefone, incluindo o código do país." );
		local.dados.txInstagram = reReplace( local.dados.txInstagram, "^@", "" );
		if ( len( local.dados.txInstagram ) AND NOT reFind( "^[A-Za-z0-9_.]{1,30}$", local.dados.txInstagram ) ) invalido( "Informe somente o usuário do Instagram, com até 30 caracteres." );
		if ( NOT isArray( variables.categorias ) AND NOT isSimpleValue( variables.categorias ) ) invalido();
		local.categorias = isArray( variables.categorias ) ? variables.categorias : listToArray( variables.categorias );
		if ( NOT arrayLen( local.categorias ) OR arrayLen( local.categorias ) GT 50 ) invalido( "Selecione de 1 a 50 categorias ativas." );
		local.dados.categorias = [];
		for ( local.id in local.categorias ) {
			if ( NOT isSimpleValue( local.id ) OR NOT reFind( "^[1-9][0-9]{0,9}$", local.id ) OR local.id GT 2147483647 ) invalido( "Categoria inválida." );
			if ( NOT arrayFind( local.dados.categorias, val( local.id ) ) ) arrayAppend( local.dados.categorias, val( local.id ) );
		}
		return local.dados;
	}

	private void function invalido( string mensagem = "Dados de fornecedor inválidos." ) {
		throw( type = "FornecedorInvalido", message = arguments.mensagem );
	}
}
