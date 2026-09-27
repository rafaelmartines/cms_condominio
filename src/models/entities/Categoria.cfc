component
	extends="BaseEntidade"
	accessors="true"
	table="cmscondominio.tb_categoria"
	datasource="cmscondominio"
	grammar="PostgresGrammar@qb"
{

	property name="cdCategoria" column="cd_categoria" sqltype="cf_sql_integer" insert="false" update="false";
	property name="txCategoria" column="tx_categoria" sqltype="cf_sql_varchar";
	property name="inAtivo" column="in_ativo" sqltype="cf_sql_boolean";
	property name="tsCriadoEm" column="ts_criadoem" sqltype="cf_sql_timestamp";
	property name="tsAtualizado" column="ts_atualizado" sqltype="cf_sql_timestamp";

	variables._key = "cdCategoria";

	public any function keyType() {
		return variables._wirebox.getInstance( "ReturningKeyType@quick" );
	}

	public any function fornecedores() {
		return belongsToMany(
			relationName = "Fornecedor",
			table = "cmscondominio.tb_fornecedor_categoria",
			foreignPivotKey = "cd_categoria",
			relatedPivotKey = "cd_fornecedor",
			parentKey = "cdCategoria",
			relatedKey = "cdFornecedor"
		);
	}

}
