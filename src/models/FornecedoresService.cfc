component singleton {

	property name="fornecedoresRepository" inject="FornecedoresRepository";
	property name="resend"                 inject="Resend";

	public FornecedoresService function init() {
		return this;
	}

	public struct function getFornecedores( required FornecedoresFiltroDTO fornecedoresFiltroDTO ) {
		// Simulando a obtenção de dados de fornecedores
		local.fornecedores = variables.fornecedoresRepository.getFornecedores( arguments.fornecedoresFiltroDTO );

		local.resultado = [];

		for ( local.fornecedor in local.fornecedores.results ) {
			local.acoes = "
            <div class='btn-group' role='group' aria-label='Basic example'>
                <a href='https://wa.me/#local.fornecedor.NR_TELEFONE#' target='_blank' class='btn btn-primary btn-success'><i class='bi bi-whatsapp'></i></a>
                <a href='fornecedores/#local.fornecedor.CD_FORNECEDOR#' class='btn btn-outline-info'><i class='bi bi-card-heading'></i></a>
            </div>
            ";

			arrayAppend(
				local.resultado,
				{
					"cdFornecedor" : local.fornecedor.CD_FORNECEDOR,
					"nmFornecedor" : local.fornecedor.NM_FORNECEDOR,
					"categorias"   : local.fornecedor.CATEGORIAS,
					"nrTelefone"   : local.fornecedor.NR_TELEFONE,
					"txInstagram"  : local.fornecedor.TX_INSTAGRAM,
					"html"         : local.acoes
				}
			);
		}

		return {
			"data"            : local.resultado,
			"recordsTotal"    : local.fornecedores.pagination.totalRecords,
			"recordsFiltered" : local.fornecedores.pagination.totalRecords
		};
	}

	public struct function getFornecedor( required numeric cdFornecedor ) {
		local.fornecedor = variables.fornecedoresRepository.getFornecedor( arguments.cdFornecedor );

		return {
			"cdFornecedor" : local.fornecedor.CD_FORNECEDOR,
			"nmFornecedor" : local.fornecedor.NM_FORNECEDOR,
			"nmEmpresa"    : local.fornecedor.NM_EMPRESA,
			"nrTelefone"   : local.fornecedor.NR_TELEFONE,
			"txInstagram"  : local.fornecedor.TX_INSTAGRAM,
			"categorias"   : local.fornecedor.CATEGORIAS
		};
	}

	public boolean function postTestemunho( required TestemunhoDTO testemunhoDTO ) {
		// Serializa o DTO para JSON
		var dtoJson = serializeJSON( testemunhoDTO );

		// Monta corpo do e-mail
		local.corpoEmail = {
			"subject" : "Novo Testemunho para Fornecedor #testemunhoDTO.getCdFornecedor()#",
			"html"    : "<h1>Novo Testemunho</h1><pre>#encodeForHTML( dtoJson )#</pre>"
		};

		return variables.resend.enviarEmail( corpoEmail = local.corpoEmail );
	}


	public boolean function postIndicacao( required IndicacaoDTO indicacaoDTO ) {
		// Serializa o DTO para JSON
		local.dtoJson = serializeJSON( arguments.indicacaoDTO );

		// Monta corpo do e-mail
		local.corpoEmail = {
			"subject" : "Nova Indicação de Fornecedor",
			"html"    : "<h1>Nova Indicação</h1><pre>#encodeForHTML( local.dtoJson )#</pre>"
		};

		return variables.resend.enviarEmail( corpoEmail = local.corpoEmail );
	}

	public array function getComentariosPorFornecedor( required numeric cdFornecedor ) {
		local.comentarios = variables.fornecedoresRepository.getComentariosPorFornecedor( arguments.cdFornecedor );

		local.resultado = [];

		for ( local.comentario in local.comentarios ) {
			arrayAppend(
				local.resultado,
				{
					"nrNota"        : local.comentario.NR_NOTA,
					"txConteudo"    : local.comentario.TX_CONTEUDO,
					"nrApartamento" : local.comentario.NR_APARTAMENTO,
					"nmNome"        : local.comentario.NM_NOME,
					"tsCriadoEm"    : local.comentario.TS_CRIADO_EM
				}
			);
		}

		return local.resultado;
	}

	public struct function getMedia( required numeric cdFornecedor ) {
		local.media = variables.fornecedoresRepository.getMedia( arguments.cdFornecedor );

		return { "media" : local.media.MEDIA };
	}

}
