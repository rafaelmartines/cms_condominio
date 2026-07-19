component singleton extends="BaseRepotisory" {

	property name="cbpaginator" inject="Pagination@cbpaginator";

	public FornecedoresRepository function init() {
		super.init();
		return this;
	}

	private struct function mesclarFiltroFornecedores( required FornecedoresFiltroDTO fornecedoresFiltroDTO ) {
		local.parametros = {};
		local.where      = "WHERE 1=1 ";
		if ( not isNull( arguments.fornecedoresFiltroDTO.getNmFornecedor() ) ) {
			local.where &= " AND UPPER(f.nm_fornecedor) LIKE :nmFornecedor ";
			structAppend(
				local.parametros,
				{
					nmFornecedor : {
						value     : "%" & uCase( arguments.fornecedoresFiltroDTO.getNmFornecedor() ) & "%",
						cfsqltype : "cf_sql_varchar"
					}
				}
			);
		}
		if ( not isNull( arguments.fornecedoresFiltroDTO.getNmEmpresa() ) ) {
			local.where &= " AND UPPER(f.nm_empresa) LIKE :nmEmpresa ";
			structAppend(
				local.parametros,
				{
					nmEmpresa : {
						value     : "%" & uCase( arguments.fornecedoresFiltroDTO.getNmEmpresa() ) & "%",
						cfsqltype : "cf_sql_varchar"
					}
				}
			);
		}
		return {
			"where"      : local.where,
			"parametros" : local.parametros
		};
	}

	public struct function getFornecedores( required FornecedoresFiltroDTO fornecedoresFiltroDTO ) {
		local.filtro = variables.mesclarFiltroFornecedores( arguments.fornecedoresFiltroDTO );
		local.page   = int( arguments.fornecedoresFiltroDTO.getStart() / arguments.fornecedoresFiltroDTO.getLength() ) + 1;

		local.sql = "
        SELECT
            f.*
        FROM
            CMSCONDOMINIO.TB_FORNECEDORES f
        #local.filtro.where#
			ORDER BY #arguments.fornecedoresFiltroDTO.getOrderColumn()# #arguments.fornecedoresFiltroDTO.getOrderDir()#
        ";

		local.resultado = variables.consulta(
			local.sql,
			local.filtro.parametros,
			true,
			"CD_FORNECEDOR"
		);

		return cbpaginator.reduceAndGenerate(
			local.resultado,
			local.page,
			arguments.fornecedoresFiltroDTO.getLength()
		);
	}

}
