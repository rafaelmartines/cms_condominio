component singleton extends="BaseRepository" {

	property name="cbpaginator" inject="Pagination@cbpaginator";
	property name="fornecedorProvider" inject="provider:Fornecedor";
	property name="fornecedorCategoriaProvider" inject="provider:FornecedorCategoria";

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
			local.status = obterStatus( "Aguardando" );
			local.criado = variables.fornecedorProvider.$get().create( {
				nmFornecedor : arguments.dados.nmFornecedor,
				nmEmpresa : arguments.dados.nmEmpresa,
				nrTelefone : arguments.dados.nrTelefone,
				txInstagram : arguments.dados.txInstagram,
				statusId : local.status
			} );
			local.id = local.criado.getCdFornecedor();
			for ( local.categoria in arguments.dados.categorias ) {
				variables.fornecedorCategoriaProvider.$get().create( {
					cdFornecedor : local.id,
					cdCategoria : local.categoria
				} );
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
		local.origem = obterStatus( "Aguardando" );
		local.destino = obterStatus( "Verificado" );
		local.resultado = variables.fornecedorProvider.$get()
			.where( "cdFornecedor", arguments.cdFornecedor )
			.where( "statusId", local.origem )
			.updateAll( { statusId : local.destino } );
		return local.resultado.result.recordCount EQ 1;
	}

	public boolean function excluirFornecedor( required numeric cdFornecedor ) {
		local.parametros = {
			id : { value : arguments.cdFornecedor, cfsqltype : "cf_sql_integer" },
			status : { value : "Aguardando", cfsqltype : "cf_sql_varchar" }
		};
		transaction {
			local.fornecedores = variables.consulta(
				"SELECT cd_fornecedor FROM cmscondominio.tb_fornecedores
				WHERE cd_fornecedor = :id AND status_id =
				(SELECT id FROM cmscondominio.tb_status_fornecedor WHERE descricao = :status)
				FOR UPDATE",
				local.parametros
			);
			if ( NOT arrayLen( local.fornecedores ) ) return false;
			local.id = { id : local.parametros.id };
			queryExecute( "DELETE FROM cmscondominio.tb_fornecedor_categoria WHERE cd_fornecedor = :id", local.id, { datasource : "cmscondominio" } );
			queryExecute( "DELETE FROM cmscondominio.tb_comentarios WHERE cd_fornecedor = :id", local.id, { datasource : "cmscondominio" } );
			queryExecute( "DELETE FROM cmscondominio.tb_fornecedores WHERE cd_fornecedor = :id", local.id, { datasource : "cmscondominio" } );
		}
		return true;
	}

	private numeric function obterStatus( required string descricao ) {
		local.resultados = variables.consulta(
			"SELECT id FROM cmscondominio.tb_status_fornecedor WHERE descricao = :descricao",
			{ descricao : { value : arguments.descricao, cfsqltype : "cf_sql_varchar" } }
		);
		if ( arrayLen( local.resultados ) NEQ 1 ) {
			throw( type = "StatusFornecedorInvalido", message = "Status de fornecedor não configurado." );
		}
		return local.resultados[ 1 ].id;
	}

}
