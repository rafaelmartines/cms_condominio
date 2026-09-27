component extends="quick.models.BaseEntity" accessors="true" {

	// No Quick 12, o eager loading transforma IDs da tabela pivô em strings.
	// A tabela pivô não pertence aos atributos da entidade relacionada: informe
	// o tipo dessas duas colunas para o PostgreSQL não comparar integer e varchar.
	public boolean function hasAttribute( required string name ) {
		return isChaveAssociacao( arguments.name ) || super.hasAttribute( arguments.name );
	}

	public boolean function attributeHasSqlType( required string name ) {
		return isChaveAssociacao( arguments.name ) || super.attributeHasSqlType( arguments.name );
	}

	public string function retrieveSqlTypeForAttribute( required string name ) {
		if ( isChaveAssociacao( arguments.name ) ) {
			return "cf_sql_integer";
		}
		return super.retrieveSqlTypeForAttribute( arguments.name );
	}

	private boolean function isChaveAssociacao( required string name ) {
		return arguments.name == "cmscondominio.tb_fornecedor_categoria.cd_fornecedor" ||
			arguments.name == "cmscondominio.tb_fornecedor_categoria.cd_categoria";
	}

}
