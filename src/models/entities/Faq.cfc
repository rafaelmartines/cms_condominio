component
	extends  ="BaseEntidade"
	accessors="true"
	table    ="cmscondominio.tb_faq"
{

	property
		name   ="cdFaq"
		column ="cd_faq"
		sqltype="cf_sql_integer"
		insert ="false"
		update ="false";
	property
		name   ="txPergunta"
		column ="tx_pergunta"
		sqltype="cf_sql_varchar";
	property
		name   ="txResposta"
		column ="tx_resposta"
		sqltype="cf_sql_longvarchar";
	property
		name   ="inAtivo"   
		column ="in_ativo"   
		sqltype="cf_sql_boolean";
	property
		name   ="tsCriadoEm"
		column ="ts_criadoem"
		sqltype="cf_sql_timestamp"
		insert ="false"
		update ="false";
	property
		name   ="tsAtualizado"
		column ="ts_atualizado"
		sqltype="cf_sql_timestamp";

	variables._key = "cdFaq";

}
