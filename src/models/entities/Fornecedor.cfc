component
	extends="BaseEntidade"
	accessors="true"
	table="cmscondominio.tb_fornecedores"
	datasource="cmscondominio"
	grammar="PostgresGrammar@qb"
{

	property name="cdFornecedor" column="cd_fornecedor" sqltype="cf_sql_integer" insert="false" update="false";
	property name="nmFornecedor" column="nm_fornecedor" sqltype="cf_sql_varchar";
	property name="nmEmpresa" column="nm_empresa" sqltype="cf_sql_varchar";
	property name="nrTelefone" column="nr_telefone" sqltype="cf_sql_bigint";
	property name="txInstagram" column="tx_instagram" sqltype="cf_sql_varchar";

	variables._key = "cdFornecedor";

	public any function keyType() {
		return variables._wirebox.getInstance( "ReturningKeyType@quick" );
	}

	public any function categorias() {
		return belongsToMany(
			relationName = "Categoria",
			table = "cmscondominio.tb_fornecedor_categoria",
			foreignPivotKey = "cd_fornecedor",
			relatedPivotKey = "cd_categoria",
			parentKey = "cdFornecedor",
			relatedKey = "cdCategoria"
		);
	}

	public any function comentarios() {
		return hasMany( "Comentario", "cdFornecedor", "cdFornecedor" );
	}

}
