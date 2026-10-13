component singleton {

	property name="faqProvider" inject="provider:entities.Faq";

	public array function listar( boolean somenteAtivos = true, string busca = "" ) {
		transaction {
			try {
				local.sql        = "SELECT cd_faq AS cdFaq, tx_pergunta AS txPergunta, tx_resposta AS txResposta, in_ativo AS inAtivo FROM cmscondominio.tb_faq WHERE 1 = 1";
				local.parametros = {};
				if ( arguments.somenteAtivos ) local.sql &= " AND in_ativo = true";
				if ( len( arguments.busca ) ) {
					// Busca literal: %, _ e aspas não são operadores nem SQL fornecido pelo usuário.
					local.sql &= " AND strpos(translate(lower(tx_pergunta), 'áàâãäéèêëíìîïóòôõöúùûüç', 'aaaaaeeeeiiiiooooouuuuc'), translate(lower(:busca), 'áàâãäéèêëíìîïóòôõöúùûüç', 'aaaaaeeeeiiiiooooouuuuc')) > 0";
					local.parametros.busca = {
						value     : arguments.busca,
						cfsqltype : "cf_sql_varchar"
					};
				}
				local.sql &= " ORDER BY tx_pergunta ASC, cd_faq ASC";
				local.resultado = queryExecute(
					local.sql,
					local.parametros,
					{
						datasource : "cmscondominio",
						returntype : "array"
					}
				);
				transactionCommit();
			} catch ( any erro ) {
				transactionRollback();
				rethrow;
			}
		}
		return local.resultado;
	}

	public array function obterPorId( required numeric cdFaq ) {
		transaction {
			try {
				local.faq       = variables.faqProvider.$get().find( arguments.cdFaq );
				local.resultado = [];
				if ( NOT isNull( local.faq ) ) {
					local.resultado.append( {
						cdFaq      : local.faq.getCdFaq(),
						txPergunta : local.faq.getTxPergunta(),
						txResposta : local.faq.getTxResposta(),
						inAtivo    : local.faq.getInAtivo()
					} );
				}
				transactionCommit();
			} catch ( any erro ) {
				transactionRollback();
				rethrow;
			}
		}
		return local.resultado;
	}

	public numeric function criar( required string txPergunta, required string txResposta ) {
		transaction {
			try {
				local.faq = variables.faqProvider
					.$get()
					.create( {
						txPergunta : arguments.txPergunta,
						txResposta : arguments.txResposta
					} );
				local.id = local.faq.getCdFaq();
				transactionCommit();
			} catch ( any erro ) {
				transactionRollback();
				rethrow;
			}
		}
		return local.id;
	}

	public boolean function editar(
		required numeric cdFaq,
		required string txPergunta,
		required string txResposta
	) {
		transaction {
			try {
				// Atualização atômica somente do conteúdo: preserva a situação em alterações concorrentes.
				local.resultado = variables.faqProvider
					.$get()
					.where( "cdFaq", arguments.cdFaq )
					.updateAll( {
						txPergunta   : arguments.txPergunta,
						txResposta   : arguments.txResposta,
						tsAtualizado : now()
					} );
				transactionCommit();
			} catch ( any erro ) {
				transactionRollback();
				rethrow;
			}
		}
		return local.resultado.result.recordCount GT 0;
	}

	public boolean function definirAtivo( required numeric cdFaq, required boolean ativo ) {
		transaction {
			try {
				// A exclusão é lógica; não remove a pergunta nem altera seu conteúdo.
				local.resultado = variables.faqProvider
					.$get()
					.where( "cdFaq", arguments.cdFaq )
					.updateAll( {
						inAtivo      : arguments.ativo,
						tsAtualizado : now()
					} );
				transactionCommit();
			} catch ( any erro ) {
				transactionRollback();
				rethrow;
			}
		}
		return local.resultado.result.recordCount GT 0;
	}

}
