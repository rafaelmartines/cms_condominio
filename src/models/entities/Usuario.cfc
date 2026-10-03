component
	extends="BaseEntidade"
	accessors="true"
	table="cmscondominio.tb_usuarios"
	datasource="cmscondominio"
	grammar="PostgresGrammar@qb"
{

	property name="cdUsuario" column="cd_usuario" sqltype="cf_sql_integer" insert="false" update="false";
	property name="nmUsuario" column="nm_usuario" sqltype="cf_sql_varchar";
	property name="txEmail" column="tx_email" sqltype="cf_sql_varchar";
	property name="txSenhaHash" column="tx_senha_hash" sqltype="cf_sql_varchar";
	property name="inAdministrador" column="in_administrador" sqltype="cf_sql_boolean";

	variables._key = "cdUsuario";

}
