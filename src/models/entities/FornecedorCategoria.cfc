component
	extends="BaseEntidade"
	accessors="true"
	table="cmscondominio.tb_fornecedor_categoria"
	datasource="cmscondominio"
	grammar="PostgresGrammar@qb"
{

	property name="cdFornecedor" column="cd_fornecedor" sqltype="cf_sql_integer";
	property name="cdCategoria" column="cd_categoria" sqltype="cf_sql_integer";

	variables._key = [ "cdFornecedor", "cdCategoria" ];

	public any function keyType() {
		return variables._wirebox.getInstance( "NullKeyType@quick" );
	}

	public any function fornecedor() {
		return belongsTo( "Fornecedor", "cdFornecedor", "cdFornecedor" );
	}

	public any function categoria() {
		return belongsTo( "Categoria", "cdCategoria", "cdCategoria" );
	}

}
