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

	public struct function getFornecedor( required any cdFornecedor ) {
		validarId( arguments.cdFornecedor );
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
		local.dados = arguments.indicacaoDTO.validar();
		local.corpoEmail = {
			subject : "Fornecedor aguardando aprovação",
			html : "<h1>Nova indicação de fornecedor</h1><p>O fornecedor <strong>#encodeForHTML( local.dados.nmFornecedor )#</strong> está aguardando aprovação.</p><p>Acesse o painel de aprovação de fornecedores para revisar a indicação.</p>"
		};
		// Uma falha no aviso permite repetir o envio sem deixar uma indicação duplicada.
		transaction {
			if ( NOT variables.fornecedoresRepository.addIndicacao( local.dados ) ) return false;
			if ( NOT variables.resend.enviarEmail( corpoEmail = local.corpoEmail ) ) {
				throw( type = "ResendException", message = "Não foi possível enviar o aviso de aprovação." );
			}
		}
		return true;
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

	public numeric function addFornecedor( required any fornecedorDTO ) {
		return variables.fornecedoresRepository.addFornecedor( arguments.fornecedorDTO.validar(), "Verificado" );
	}

	public array function listarAguardando() {
		return variables.fornecedoresRepository.listarAguardando();
	}

	public struct function listarFornecedores( required FornecedoresFiltroDTO fornecedoresFiltroDTO ) {
		return getFornecedores( arguments.fornecedoresFiltroDTO );
	}

	public void function aprovarFornecedor( required any cdFornecedor ) {
		validarId( arguments.cdFornecedor );
		if ( NOT variables.fornecedoresRepository.aprovarFornecedor( arguments.cdFornecedor ) ) {
			throw( type = "FornecedorNaoAguardando", message = "Fornecedor inexistente ou que não está mais aguardando aprovação." );
		}
	}

	public void function excluirFornecedor( required any cdFornecedor ) {
		validarId( arguments.cdFornecedor );
		if ( NOT variables.fornecedoresRepository.excluirFornecedor( arguments.cdFornecedor ) ) {
			throw( type = "FornecedorNaoAguardando", message = "Fornecedor inexistente ou que não está mais aguardando aprovação." );
		}
	}

	private void function validarId( required any id ) {
		if ( NOT isSimpleValue( arguments.id ) OR NOT reFind( "^[1-9][0-9]{0,9}$", arguments.id ) OR arguments.id GT 2147483647 ) {
			throw( type = "FornecedorInvalido", message = "Identificador de fornecedor inválido." );
		}
	}

}
