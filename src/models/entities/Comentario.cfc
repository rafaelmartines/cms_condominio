component
	extends  ="BaseEntidade"
	accessors="true"
	table    ="cmscondominio.tb_comentarios"
{

	property
		name   ="cdComentario"
		column ="cd_comentario"
		sqltype="cf_sql_integer"
		insert ="false"
		update ="false";
	property
		name   ="cdFornecedor"  
		column ="cd_fornecedor"   
		sqltype="cf_sql_integer";
	property
		name   ="nrNota"        
		column ="nr_nota"         
		sqltype="cf_sql_integer";
	property
		name   ="nrApartamento" 
		column ="nr_apartamento"  
		sqltype="cf_sql_integer";
	property
		name   ="nmNome"        
		column ="nm_nome"         
		sqltype="cf_sql_varchar";
	property
		name   ="txConteudo"    
		column ="tx_conteudo"     
		sqltype="cf_sql_varchar";
	property
		name   ="tsCriadoEm"    
		column ="ts_criado_em"    
		sqltype="cf_sql_timestamp";
	property
		name   ="tsAtualizadoEm"
		column ="ts_atualizado_em"
		sqltype="cf_sql_timestamp";

	variables._key = "cdComentario";

	// Usa a chave autoincremental padrão: o Lucee retorna o ID nos metadados do INSERT.

	public any function fornecedor() {
		return belongsTo(
			"Fornecedor",
			"cdFornecedor",
			"cdFornecedor"
		);
	}

}
