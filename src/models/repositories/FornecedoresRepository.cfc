component singleton extends="BaseRepository" {

	property name="cbpaginator" inject="Pagination@cbpaginator";

	public FornecedoresRepository function init() {
		super.init();
		return this;
	}

	private struct function mesclarFiltroFornecedores( required FornecedoresFiltroDTO fornecedoresFiltroDTO ) {
		local.parametros = {};
		local.where      = "WHERE 1=1 ";
		if (
			not isNull( arguments.fornecedoresFiltroDTO.getNmFornecedor() ) and len(
				trim( arguments.fornecedoresFiltroDTO.getNmFornecedor() )
			)
		) {
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
		if (
			not isNull( arguments.fornecedoresFiltroDTO.getCdCategoria() ) and len(
				trim( arguments.fornecedoresFiltroDTO.getCdCategoria() )
			)
		) {
			local.where &= " AND fc.cd_categoria = :cdCategoria ";
			structAppend(
				local.parametros,
				{
					cdCategoria : {
						value     : arguments.fornecedoresFiltroDTO.getCdCategoria(),
						cfsqltype : "cf_sql_integer"
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
		WITH fornecedor_categoria AS (
		SELECT
			fc.cd_fornecedor,
			c.tx_categoria,
			c.cd_categoria
		FROM
			cmscondominio.tb_fornecedor_categoria fc
			JOIN cmscondominio.tb_categoria c ON fc.cd_categoria = c.cd_categoria
		)
		SELECT
			f.*,
			STRING_AGG(fc.tx_categoria, ', ') AS categorias
		FROM
  			cmscondominio.tb_fornecedores f
  		LEFT JOIN fornecedor_categoria fc ON f.cd_fornecedor = fc.cd_fornecedor
		#local.filtro.where#
		GROUP BY
			f.cd_fornecedor,
			f.nm_fornecedor,
			f.nm_empresa,
			f.nr_telefone,
			f.tx_instagram
		ORDER BY
			#arguments.fornecedoresFiltroDTO.getOrderColumn()# #arguments.fornecedoresFiltroDTO.getOrderDir()#
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

	public struct function getFornecedor( required numeric cdFornecedor ) {
		local.sql = "
			WITH fornecedor_categoria AS (
			SELECT
				fc.cd_fornecedor,
				c.tx_categoria,
				c.cd_categoria
			FROM
				cmscondominio.tb_fornecedor_categoria fc
				JOIN cmscondominio.tb_categoria c ON fc.cd_categoria = c.cd_categoria
			)
			SELECT
				f.*,
				STRING_AGG(fc.tx_categoria, ', ') AS categorias
			FROM
				cmscondominio.tb_fornecedores f
			LEFT JOIN fornecedor_categoria fc ON f.cd_fornecedor = fc.cd_fornecedor
			WHERE
				f.cd_fornecedor = :cdFornecedor
			GROUP BY
				f.cd_fornecedor,
				f.nm_fornecedor,
				f.nm_empresa,
				f.nr_telefone,
				f.tx_instagram
		";

		local.parametros = {
			cdFornecedor : {
				value     : arguments.cdFornecedor,
				cfsqltype : "cf_sql_integer"
			}
		};

		return variables.consulta( local.sql, local.parametros, false );
	}

}
