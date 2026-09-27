component singleton {

	property name="categoriaRepository" inject="repositories.CategoriaRepository";

	public array function listarParaGestao() {
		return variables.categoriaRepository.listarParaGestao().map( function( categoria ) {
			return paraDados( categoria );
		} );
	}

	public struct function obterCategoria( required any cdCategoria ) {
		validarId( arguments.cdCategoria );
		var categoria = variables.categoriaRepository.obterPorId( arguments.cdCategoria );
		if ( isNull( categoria ) ) {
			throw( type = "CategoriaNaoEncontrada", message = "Categoria não encontrada." );
		}
		return paraDados( categoria );
	}

	public void function editarCategoria( required any cdCategoria, required any txCategoria ) {
		validarId( arguments.cdCategoria );
		if ( !isSimpleValue( arguments.txCategoria ) || !len( trim( arguments.txCategoria ) ) || len( trim( arguments.txCategoria ) ) > 100 ) {
			throw( type = "CategoriaInvalida", message = "Informe um nome de categoria com 1 a 100 caracteres." );
		}
		if ( !variables.categoriaRepository.editar( arguments.cdCategoria, trim( arguments.txCategoria ) ) ) {
			throw( type = "CategoriaNaoEncontrada", message = "Categoria não encontrada." );
		}
	}

	public void function inativarCategoria( required any cdCategoria ) {
		validarId( arguments.cdCategoria );
		if ( !variables.categoriaRepository.inativar( arguments.cdCategoria ) ) {
			throw( type = "CategoriaNaoEncontrada", message = "Categoria não encontrada." );
		}
	}

	private void function validarId( required any cdCategoria ) {
		if ( !isSimpleValue( arguments.cdCategoria ) || !reFind( "^[1-9][0-9]{0,9}$", arguments.cdCategoria ) || arguments.cdCategoria > 2147483647 ) {
			throw( type = "CategoriaInvalida", message = "Identificador de categoria inválido." );
		}
	}

	private struct function paraDados( required any categoria ) {
		return {
			cdCategoria : arguments.categoria.getCdCategoria(),
			txCategoria : arguments.categoria.getTxCategoria(),
			inAtivo : !isNull( arguments.categoria.getInAtivo() ) && arguments.categoria.getInAtivo() == true
		};
	}

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
