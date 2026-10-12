component singleton {
	public array function listar( boolean somenteAtivos = true, string busca = "" ) {
		local.sql = "SELECT cd_faq AS cdFaq, tx_pergunta AS txPergunta, tx_resposta AS txResposta, in_ativo AS inAtivo FROM cmscondominio.tb_faq WHERE 1 = 1";
		local.parametros = {};
		if ( arguments.somenteAtivos ) local.sql &= " AND in_ativo = true";
		if ( len( arguments.busca ) ) {
			// Busca literal: %, _ e aspas não são operadores nem SQL fornecido pelo usuário.
			local.sql &= " AND strpos(translate(lower(tx_pergunta), 'áàâãäéèêëíìîïóòôõöúùûüç', 'aaaaaeeeeiiiiooooouuuuc'), translate(lower(:busca), 'áàâãäéèêëíìîïóòôõöúùûüç', 'aaaaaeeeeiiiiooooouuuuc')) > 0";
			local.parametros.busca = { value : arguments.busca, cfsqltype : "cf_sql_varchar" };
		}
		local.sql &= " ORDER BY tx_pergunta ASC, cd_faq ASC";
		return queryExecute( local.sql, local.parametros, { datasource : "cmscondominio", returntype : "array" } );
	}

	public array function obterPorId( required numeric cdFaq ) {
		return queryExecute(
			"SELECT cd_faq AS cdFaq, tx_pergunta AS txPergunta, tx_resposta AS txResposta, in_ativo AS inAtivo FROM cmscondominio.tb_faq WHERE cd_faq = :id",
			{ id : { value : arguments.cdFaq, cfsqltype : "cf_sql_integer" } },
			{ datasource : "cmscondominio", returntype : "array" }
		);
	}

	public numeric function criar( required string txPergunta, required string txResposta ) {
		local.resultado = queryExecute(
			"INSERT INTO cmscondominio.tb_faq (tx_pergunta, tx_resposta) VALUES (:pergunta, :resposta) RETURNING cd_faq",
			parametrosConteudo( arguments.txPergunta, arguments.txResposta ),
			{ datasource : "cmscondominio", returntype : "array" }
		);
		return local.resultado[ 1 ].cd_faq;
	}

	public boolean function editar( required numeric cdFaq, required string txPergunta, required string txResposta ) {
		local.parametros = parametrosConteudo( arguments.txPergunta, arguments.txResposta );
		local.parametros.id = { value : arguments.cdFaq, cfsqltype : "cf_sql_integer" };
		local.resultado = queryExecute(
			"UPDATE cmscondominio.tb_faq SET tx_pergunta = :pergunta, tx_resposta = :resposta, ts_atualizado = CURRENT_TIMESTAMP WHERE cd_faq = :id RETURNING cd_faq",
			local.parametros, { datasource : "cmscondominio", returntype : "array" }
		);
		return arrayLen( local.resultado ) GT 0;
	}

	public boolean function definirAtivo( required numeric cdFaq, required boolean ativo ) {
		local.resultado = queryExecute(
			"UPDATE cmscondominio.tb_faq SET in_ativo = :ativo, ts_atualizado = CURRENT_TIMESTAMP WHERE cd_faq = :id RETURNING cd_faq",
			{ id : { value : arguments.cdFaq, cfsqltype : "cf_sql_integer" }, ativo : { value : arguments.ativo, cfsqltype : "cf_sql_boolean" } },
			{ datasource : "cmscondominio", returntype : "array" }
		);
		return arrayLen( local.resultado ) GT 0;
	}

	private struct function parametrosConteudo( required string txPergunta, required string txResposta ) {
		return {
			pergunta : { value : arguments.txPergunta, cfsqltype : "cf_sql_varchar" },
			resposta : { value : arguments.txResposta, cfsqltype : "cf_sql_longvarchar" }
		};
	}
}
