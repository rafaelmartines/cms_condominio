component singleton {

	property name="fornecedoresRepository" inject="FornecedoresRepository";

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
                <a href='javascript:alert(""Em breve"");' class='btn btn-outline-secondary'><i class='bi bi-share-fill'></i></a>
                <a href='javascript:alert(""Em breve"");' class='btn btn-outline-danger'><i class='bi bi-envelope-dash-fill'></i></a>
            </div>
            ";

			arrayAppend(
				local.resultado,
				{
					"cdFornecedor" : local.fornecedor.CD_FORNECEDOR,
					"nmFornecedor" : local.fornecedor.NM_FORNECEDOR,
					"nmEmpresa"    : local.fornecedor.NM_EMPRESA,
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

}
