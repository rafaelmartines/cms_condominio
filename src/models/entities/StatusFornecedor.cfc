component extends="BaseEntidade" accessors="true" table="cmscondominio.tb_status_fornecedor"
	datasource="cmscondominio" grammar="PostgresGrammar@qb" {

	property name="id" sqltype="cf_sql_integer";
	property name="descricao" sqltype="cf_sql_varchar";
	variables._key = "id";

	public any function fornecedores() {
		return hasMany( "Fornecedor", "statusId", "id" );
	}
}
