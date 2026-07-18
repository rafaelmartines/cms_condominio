component singleton {

	public BaseRepotisory function init() {
		return this;
	}

	public any function consulta(
		required string sql,
		struct params           = {},
		boolean multiplasLinhas = true,
		string keyColumn
	) {
		local.resultado = queryExecute(
			arguments.sql,
			arguments.params,
			{
				returntype : "struct",
				keyColumn  : "CD_FORNECEDOR"
			}
		);

		if ( not arguments.multiplasLinhas ) {
			local.resultado = arrayFirst( local.resultado );
		}

		return local.resultado;
	}

	public boolean function checkDatabase() {
		local.result = {};
		try {
			// Consulta mínima para testar se o banco responde
			local.result = queryExecute( "SELECT 1 AS ok", [] );

			if ( local.result.recordCount gt 0 && local.result.ok[ 1 ] eq 1 ) {
				return true;
			} else {
				return false;
			}
		} catch ( any e ) {
			// Se ocorrer erro, significa que não conseguiu conectar
			return false;
		}
	}

}
