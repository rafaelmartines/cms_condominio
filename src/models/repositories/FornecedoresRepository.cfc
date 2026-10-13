component singleton extends="BaseRepository" {

	// Métodos internos participam da transação externa, inclusive a do envio da indicação.
	// Somente quem inicia a transação confirma ou reverte; falhas são propagadas.

	property name="cbpaginator"                 inject="Pagination@cbpaginator";
	property name="fornecedorProvider"          inject="provider:Fornecedor";
	property name="fornecedorCategoriaProvider" inject="provider:FornecedorCategoria";
	property name="comentarioProvider"          inject="provider:Comentario";

	public FornecedoresRepository function init() {
		super.init();
		return this;
	}

	private struct function mesclarFiltroFornecedores( required FornecedoresFiltroDTO fornecedoresFiltroDTO ) {
		local.parametros = {
			status : {
				value     : "Verificado",
				cfsqltype : "cf_sql_varchar"
			}
		};
		local.where = "WHERE f.status_id = (SELECT id FROM cmscondominio.tb_status_fornecedor WHERE descricao = :status) ";
		if (
			NOT isNull( arguments.fornecedoresFiltroDTO.getNmFornecedor() ) AND len(
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
			NOT isNull( arguments.fornecedoresFiltroDTO.getCdCategoria() ) AND len(
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
		local.transacaoPropria = NOT isWithinTransaction();
		transaction {
			try {
				local.filtro = variables.mesclarFiltroFornecedores( arguments.fornecedoresFiltroDTO );
				if (
					arguments.fornecedoresFiltroDTO.getLength() LTE 0 OR arguments.fornecedoresFiltroDTO.getLength() GT 100 OR arguments.fornecedoresFiltroDTO.getStart() LT 0 OR fix(
						arguments.fornecedoresFiltroDTO.getLength()
					) NEQ arguments.fornecedoresFiltroDTO.getLength() OR fix(
						arguments.fornecedoresFiltroDTO.getStart()
					) NEQ arguments.fornecedoresFiltroDTO.getStart()
				) {
					throw( type = "FornecedorInvalido", message = "Paginação inválida." );
				}
				local.direcao = uCase( arguments.fornecedoresFiltroDTO.getOrderDir() );
				if ( NOT listFind( "ASC,DESC", local.direcao ) )
					throw( type = "FornecedorInvalido", message = "Ordenação inválida." );
				local.page = int(
					arguments.fornecedoresFiltroDTO.getStart() / arguments.fornecedoresFiltroDTO.getLength()
				) + 1;

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

				local.resultado = variables.consulta(
					local.sql,
					local.filtro.parametros,
					true,
					"CD_FORNECEDOR"
				);

				local.retorno = cbpaginator.reduceAndGenerate(
					local.resultado,
					local.page,
					arguments.fornecedoresFiltroDTO.getLength()
				);
				if ( local.transacaoPropria ) transactionCommit();
			} catch ( any erro ) {
				if ( local.transacaoPropria ) transactionRollback();
				rethrow;
			}
		}
		return local.retorno;
	}

	public struct function getFornecedor( required numeric cdFornecedor ) {
		local.transacaoPropria = NOT isWithinTransaction();
		transaction {
			try {
				local.fornecedor = variables.fornecedorProvider
					.$get()
					.with( "categorias" )
					.where( "statusId", obterStatus( "Verificado" ) )
					.find( arguments.cdFornecedor );
				if ( isNull( local.fornecedor ) ) {
					throw( type = "FornecedorNaoEncontrado", message = "Fornecedor não encontrado." );
				}
				local.categorias = [];
				for ( local.categoria in local.fornecedor.getCategorias() ) {
					local.categorias.append( local.categoria.getTxCategoria() );
				}
				local.retorno = {
					cd_fornecedor : local.fornecedor.getCdFornecedor(),
					nm_fornecedor : local.fornecedor.getNmFornecedor(),
					nm_empresa    : local.fornecedor.getNmEmpresa(),
					nr_telefone   : local.fornecedor.getNrTelefone(),
					tx_instagram  : local.fornecedor.getTxInstagram(),
					status_id     : local.fornecedor.getStatusId(),
					categorias    : arrayToList( local.categorias, ", " )
				};
				if ( local.transacaoPropria ) transactionCommit();
			} catch ( any erro ) {
				if ( local.transacaoPropria ) transactionRollback();
				rethrow;
			}
		}
		return local.retorno;
	}

	public array function getComentariosPorFornecedor( required numeric cdFornecedor ) {
		local.transacaoPropria = NOT isWithinTransaction();
		transaction {
			try {
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

				local.retorno = variables.consulta( local.sql, local.parametros, true );
				if ( local.transacaoPropria ) transactionCommit();
			} catch ( any erro ) {
				if ( local.transacaoPropria ) transactionRollback();
				rethrow;
			}
		}
		return local.retorno;
	}

	public struct function getMedia( required numeric cdFornecedor ) {
		local.transacaoPropria = NOT isWithinTransaction();
		transaction {
			try {
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

				local.retorno = variables.consulta( local.sql, local.parametros, false );
				if ( local.transacaoPropria ) transactionCommit();
			} catch ( any erro ) {
				if ( local.transacaoPropria ) transactionRollback();
				rethrow;
			}
		}
		return local.retorno;
	}

	public numeric function addFornecedor( required struct dados, string status = "Aguardando" ) {
		local.transacaoPropria = NOT isWithinTransaction();
		transaction {
			try {
				if ( NOT listFind( "Aguardando,Verificado", arguments.status ) ) {
					throw( type = "StatusFornecedorInvalido", message = "Status de fornecedor inválido." );
				}
				// Bloqueia alterações das categorias durante a criação dos vínculos.
				local.categorias = queryExecute(
					"SELECT cd_categoria FROM cmscondominio.tb_categoria WHERE cd_categoria IN (:ids) AND in_ativo = true FOR SHARE",
					{
						ids : {
							value     : arrayToList( arguments.dados.categorias ),
							list      : true,
							cfsqltype : "cf_sql_integer"
						}
					},
					{ datasource : "cmscondominio" }
				);
				if ( local.categorias.recordCount NEQ arrayLen( arguments.dados.categorias ) ) {
					throw( type = "FornecedorInvalido", message = "Selecione somente categorias existentes e ativas." );
				}
				local.status = obterStatus( arguments.status );
				local.criado = variables.fornecedorProvider
					.$get()
					.create( {
						nmFornecedor : arguments.dados.nmFornecedor,
						nmEmpresa    : arguments.dados.nmEmpresa,
						nrTelefone   : arguments.dados.nrTelefone,
						txInstagram  : arguments.dados.txInstagram,
						statusId     : local.status
					} );
				local.id = local.criado.getCdFornecedor();
				for ( local.categoria in arguments.dados.categorias ) {
					variables.fornecedorCategoriaProvider
						.$get()
						.create( {
							cdFornecedor : local.id,
							cdCategoria  : local.categoria
						} );
				}
				local.retorno = local.id;
				if ( local.transacaoPropria ) transactionCommit();
			} catch ( any erro ) {
				if ( local.transacaoPropria ) transactionRollback();
				rethrow;
			}
		}
		return local.retorno;
	}

	public boolean function addIndicacao( required struct dados ) {
		local.transacaoPropria = NOT isWithinTransaction();
		transaction {
			try {
				local.id = addFornecedor( arguments.dados );
				variables.comentarioProvider
					.$get()
					.create( {
						cdFornecedor  : local.id,
						nrApartamento : arguments.dados.nrApartamento,
						nmNome        : arguments.dados.nmNome,
						txConteudo    : arguments.dados.txConteudo,
						nrNota        : arguments.dados.nrNota
					} );
				local.retorno = true;
				if ( local.transacaoPropria ) transactionCommit();
			} catch ( any erro ) {
				if ( local.transacaoPropria ) transactionRollback();
				rethrow;
			}
		}
		return local.retorno;
	}

	public array function listarAguardando() {
		local.transacaoPropria = NOT isWithinTransaction();
		transaction {
			try {
				local.retorno = variables.consulta(
					"SELECT f.cd_fornecedor, f.nm_fornecedor, f.nm_empresa, f.nr_telefone, f.tx_instagram,
					COALESCE(STRING_AGG(c.tx_categoria, ', ' ORDER BY c.tx_categoria), '') AS categorias
					FROM cmscondominio.tb_fornecedores f
					LEFT JOIN cmscondominio.tb_fornecedor_categoria fc ON fc.cd_fornecedor = f.cd_fornecedor
					LEFT JOIN cmscondominio.tb_categoria c ON c.cd_categoria = fc.cd_categoria
					WHERE f.status_id = (SELECT id FROM cmscondominio.tb_status_fornecedor WHERE descricao = :status)
					GROUP BY f.cd_fornecedor ORDER BY f.nm_fornecedor, f.cd_fornecedor",
					{
						status : {
							value     : "Aguardando",
							cfsqltype : "cf_sql_varchar"
						}
					}
				);
				if ( local.transacaoPropria ) transactionCommit();
			} catch ( any erro ) {
				if ( local.transacaoPropria ) transactionRollback();
				rethrow;
			}
		}
		return local.retorno;
	}

	public boolean function aprovarFornecedor( required numeric cdFornecedor ) {
		local.transacaoPropria = NOT isWithinTransaction();
		transaction {
			try {
				local.origem    = obterStatus( "Aguardando" );
				local.destino   = obterStatus( "Verificado" );
				local.resultado = variables.fornecedorProvider
					.$get()
					.where( "cdFornecedor", arguments.cdFornecedor )
					.where( "statusId", local.origem )
					.updateAll( { statusId : local.destino } );
				local.retorno = local.resultado.result.recordCount EQ 1;
				if ( local.transacaoPropria ) transactionCommit();
			} catch ( any erro ) {
				if ( local.transacaoPropria ) transactionRollback();
				rethrow;
			}
		}
		return local.retorno;
	}

	public boolean function excluirFornecedor( required numeric cdFornecedor ) {
		local.transacaoPropria = NOT isWithinTransaction();
		transaction {
			try {
				// O lock impede que a aprovação concorra com a remoção dos vínculos.
				local.fornecedor = variables.fornecedorProvider
					.$get()
					.where( "statusId", obterStatus( "Aguardando" ) )
					.lockForUpdate()
					.find( arguments.cdFornecedor );
				local.excluido = false;
				if ( NOT isNull( local.fornecedor ) ) {
					variables.fornecedorCategoriaProvider
						.$get()
						.where( "cdFornecedor", arguments.cdFornecedor )
						.deleteAll();
					variables.comentarioProvider
						.$get()
						.where( "cdFornecedor", arguments.cdFornecedor )
						.deleteAll();
					local.fornecedor.delete();
					local.excluido = true;
				}
				local.retorno = local.excluido;
				if ( local.transacaoPropria ) transactionCommit();
			} catch ( any erro ) {
				if ( local.transacaoPropria ) transactionRollback();
				rethrow;
			}
		}
		return local.retorno;
	}

	private numeric function obterStatus( required string descricao ) {
		local.transacaoPropria = NOT isWithinTransaction();
		transaction {
			try {
				local.resultados = variables.consulta(
					"SELECT id FROM cmscondominio.tb_status_fornecedor WHERE descricao = :descricao",
					{
						descricao : {
							value     : arguments.descricao,
							cfsqltype : "cf_sql_varchar"
						}
					}
				);
				if ( arrayLen( local.resultados ) NEQ 1 ) {
					throw( type = "StatusFornecedorInvalido", message = "Status de fornecedor não configurado." );
				}
				local.retorno = arrayFirst( local.resultados ).id;
				if ( local.transacaoPropria ) transactionCommit();
			} catch ( any erro ) {
				if ( local.transacaoPropria ) transactionRollback();
				rethrow;
			}
		}
		return local.retorno;
	}

}
