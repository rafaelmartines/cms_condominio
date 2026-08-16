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
		local.corpoEmail = {
			"subject" : "Novo Testemunho para Fornecedor #testemunhoDTO.getCdFornecedor()#",
			"html"    : "<h1>Novo Testemunho</h1><p>Fornecedor: #testemunhoDTO.getCdFornecedor()#</p><p>Nota: #testemunhoDTO.getNrNota()#</p><p>Apartamento: #testemunhoDTO.getNrApartamento()#</p><p>Nome: #testemunhoDTO.getNmNome()#</p><p>Conteúdo: #testemunhoDTO.getTxConteudo()#</p>"
		};

		return variables.resend.enviarEmail( corpoEmail = local.corpoEmail );
	}

}
