component singleton {

	property name="categoriaRepository" inject="repositories.CategoriaRepository";

	public CategoriaService function init() {
		return this;
	}

	public array function obterCategorias() {
		local.resultado = [];

		local.categorias = variables.categoriaRepository.obterCategorias();

		for ( local.categoria in local.categorias ) {
			arrayAppend(
				local.resultado,
				{
					"cdCategoria" : local.categoria.CD_CATEGORIA,
					"txCategoria" : local.categoria.TX_CATEGORIA
				}
			);
		}

		return local.resultado;
	}

}
