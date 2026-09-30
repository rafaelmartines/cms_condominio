component singleton extends="BaseRepository" {

	property name="cbpaginator" inject="Pagination@cbpaginator";

	public FornecedoresRepository function init() {
		super.init();
		return this;
	}

	private struct function mesclarFiltroFornecedores( required FornecedoresFiltroDTO fornecedoresFiltroDTO ) {
		local.parametros = { status : { value : "Verificado", cfsqltype : "cf_sql_varchar" } };
		local.where      = "WHERE f.status_id = (SELECT id FROM cmscondominio.tb_status_fornecedor WHERE descricao = :status) ";
		if (
			not isNull( arguments.fornecedoresFiltroDTO.getNmFornecedor() ) and len(
				trim( arguments.fornecedoresFiltroDTO.getNmFornecedor() )
			)
		) {
			local.where &= " AND UPPER(cmscondominio.unaccent(CAST(f.nm_fornecedor as text))) LIKE cmscondominio.unaccent(CAST(:nmFornecedor as text)) ";
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
		if ( arguments.fornecedoresFiltroDTO.getLength() LTE 0 OR arguments.fornecedoresFiltroDTO.getLength() GT 100 OR arguments.fornecedoresFiltroDTO.getStart() LT 0 OR fix( arguments.fornecedoresFiltroDTO.getLength() ) NEQ arguments.fornecedoresFiltroDTO.getLength() OR fix( arguments.fornecedoresFiltroDTO.getStart() ) NEQ arguments.fornecedoresFiltroDTO.getStart() ) {
			throw( type = "FornecedorInvalido", message = "Paginação inválida." );
		}
		local.direcao = uCase( arguments.fornecedoresFiltroDTO.getOrderDir() );
		if ( NOT listFind( "ASC,DESC", local.direcao ) ) throw( type = "FornecedorInvalido", message = "Ordenação inválida." );
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
			#arguments.fornecedoresFiltroDTO.getOrderColumn()# #local.direcao#
        ";

		// writeDump( var = local.sql, label = "SQL Fornecedores" );
		// writeDump( var = local.filtro.parametros, label = "Parâmetros Fornecedores" );
		// abort;
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
				AND f.status_id = (SELECT id FROM cmscondominio.tb_status_fornecedor WHERE descricao = :status)
			GROUP BY
				f.cd_fornecedor,
				f.nm_fornecedor,
				f.nm_empresa,
				f.nr_telefone,
				f.tx_instagram
		";

		local.parametros = {
			status : { value : "Verificado", cfsqltype : "cf_sql_varchar" },
			cdFornecedor : {
				value     : arguments.cdFornecedor,
				cfsqltype : "cf_sql_integer"
			}
		};

		local.resultados = variables.consulta( local.sql, local.parametros, true );
		if ( NOT arrayLen( local.resultados ) ) throw( type = "FornecedorNaoEncontrado", message = "Fornecedor não encontrado." );
		return local.resultados[ 1 ];
	}

	public array function getComentariosPorFornecedor( required numeric cdFornecedor ) {
		local.sql = "
			SELECT
				c.*
			FROM
				cmscondominio.tb_comentarios c
			WHERE
				c.cd_fornecedor = :cdFornecedor
		";

		local.parametros = {
			cdFornecedor : {
				value     : arguments.cdFornecedor,
				cfsqltype : "cf_sql_integer"
			}
		};

		return variables.consulta( local.sql, local.parametros, true );
	}

	public struct function getMedia( required numeric cdFornecedor ) {
		local.sql = "
			SELECT
				COALESCE(AVG(c.nr_nota), 0) AS media
			FROM
				cmscondominio.tb_comentarios c
			WHERE
				c.cd_fornecedor = :cdFornecedor;
		";

		local.parametros = {
			cdFornecedor : {
				value     : arguments.cdFornecedor,
				cfsqltype : "cf_sql_integer"
			}
		};

		return variables.consulta( local.sql, local.parametros, false );
	}

	public numeric function addFornecedor( required struct dados ) {
		transaction {
			// Bloqueia alterações das categorias durante a criação dos vínculos.
			local.categorias = queryExecute(
				"SELECT cd_categoria FROM cmscondominio.tb_categoria WHERE cd_categoria IN (:ids) AND in_ativo = true FOR SHARE",
				{ ids : { value : arrayToList( arguments.dados.categorias ), list : true, cfsqltype : "cf_sql_integer" } },
				{ datasource : "cmscondominio" }
			);
			if ( local.categorias.recordCount NEQ arrayLen( arguments.dados.categorias ) ) {
				throw( type = "FornecedorInvalido", message = "Selecione somente categorias existentes e ativas." );
			}
			local.criado = queryExecute(
				"INSERT INTO cmscondominio.tb_fornecedores (nm_fornecedor, nm_empresa, nr_telefone, tx_instagram, status_id)
				VALUES (:nome, :empresa, :telefone, :instagram, (SELECT id FROM cmscondominio.tb_status_fornecedor WHERE descricao = :status)) RETURNING cd_fornecedor",
				{
					nome : { value : arguments.dados.nmFornecedor, cfsqltype : "cf_sql_varchar" },
					empresa : { value : arguments.dados.nmEmpresa, cfsqltype : "cf_sql_varchar" },
					telefone : { value : arguments.dados.nrTelefone, cfsqltype : "cf_sql_bigint" },
					instagram : { value : arguments.dados.txInstagram, cfsqltype : "cf_sql_varchar" },
					status : { value : "Aguardando", cfsqltype : "cf_sql_varchar" }
				},
				{ datasource : "cmscondominio" }
			);
			local.id = local.criado.cd_fornecedor[ 1 ];
			for ( local.categoria in arguments.dados.categorias ) {
				queryExecute(
					"INSERT INTO cmscondominio.tb_fornecedor_categoria (cd_fornecedor, cd_categoria) VALUES (:fornecedor, :categoria)",
					{
						fornecedor : { value : local.id, cfsqltype : "cf_sql_integer" },
						categoria : { value : local.categoria, cfsqltype : "cf_sql_integer" }
					},
					{ datasource : "cmscondominio" }
				);
			}
		}
		return local.id;
	}

	public array function listarAguardando() {
		return variables.consulta(
			"SELECT f.cd_fornecedor, f.nm_fornecedor, f.nm_empresa, f.nr_telefone, f.tx_instagram,
			COALESCE(STRING_AGG(c.tx_categoria, ', ' ORDER BY c.tx_categoria), '') AS categorias
			FROM cmscondominio.tb_fornecedores f
			LEFT JOIN cmscondominio.tb_fornecedor_categoria fc ON fc.cd_fornecedor = f.cd_fornecedor
			LEFT JOIN cmscondominio.tb_categoria c ON c.cd_categoria = fc.cd_categoria
			WHERE f.status_id = (SELECT id FROM cmscondominio.tb_status_fornecedor WHERE descricao = :status)
			GROUP BY f.cd_fornecedor ORDER BY f.nm_fornecedor, f.cd_fornecedor",
			{ status : { value : "Aguardando", cfsqltype : "cf_sql_varchar" } }
		);
	}

	public boolean function aprovarFornecedor( required numeric cdFornecedor ) {
		local.resultado = queryExecute(
			"UPDATE cmscondominio.tb_fornecedores SET status_id = (SELECT id FROM cmscondominio.tb_status_fornecedor WHERE descricao = :destino)
			WHERE cd_fornecedor = :id AND status_id = (SELECT id FROM cmscondominio.tb_status_fornecedor WHERE descricao = :origem)
			RETURNING cd_fornecedor",
			{
				id : { value : arguments.cdFornecedor, cfsqltype : "cf_sql_integer" },
				origem : { value : "Aguardando", cfsqltype : "cf_sql_varchar" },
				destino : { value : "Verificado", cfsqltype : "cf_sql_varchar" }
			},
			{ datasource : "cmscondominio" }
		);
		return local.resultado.recordCount EQ 1;
	}

}
