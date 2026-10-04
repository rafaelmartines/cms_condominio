component singleton {

	property name="categoriaRepository" inject="repositories.CategoriaRepository";
	property name="validationManager" inject="ValidationManager@cbvalidation";

	public array function listarParaGestao() {
		return variables.categoriaRepository.listarParaGestao().map( function( categoria ) {
			return paraDados( categoria );
		} );
	}

	public struct function obterCategoria( required any cdCategoria ) {
		local.categoria = variables.categoriaRepository.obterPorId( arguments.cdCategoria );
		if ( isNull( local.categoria ) ) {
			throw( type = "CategoriaNaoEncontrada", message = "Categoria não encontrada." );
		}
		return paraDados( local.categoria );
	}

	public void function editarCategoria( required any cdCategoria, required any txCategoria ) {
		validarNome( arguments.txCategoria );
		if ( NOT variables.categoriaRepository.editar( arguments.cdCategoria, trim( arguments.txCategoria ) ) ) {
			throw( type = "CategoriaNaoEncontrada", message = "Categoria não encontrada." );
		}
	}

	public void function inativarCategoria( required any cdCategoria ) {
		if ( NOT variables.categoriaRepository.inativar( arguments.cdCategoria ) ) {
			throw( type = "CategoriaNaoEncontrada", message = "Categoria não encontrada." );
		}
	}

	public void function criarCategoria( required any txCategoria ) {
		validarNome( arguments.txCategoria );
		variables.categoriaRepository.criar( trim( arguments.txCategoria ) );
	}

	public struct function reativarCategoria( required any cdCategoria ) {
		if ( NOT isSimpleValue( arguments.cdCategoria ) OR NOT reFind( "^[1-9][0-9]{0,9}$", arguments.cdCategoria ) OR arguments.cdCategoria GT 2147483647 ) {
			throw( type = "CategoriaInvalida", message = "Identificador de categoria inválido." );
		}
		if ( NOT variables.categoriaRepository.reativar( arguments.cdCategoria ) ) {
			throw( type = "CategoriaNaoEncontrada", message = "Categoria não encontrada." );
		}
		return obterCategoria( arguments.cdCategoria );
	}

	private void function validarNome( required any txCategoria ) {
		local.dto = new dto.CategoriaDTO();
		local.dto.setTxCategoria( arguments.txCategoria );
		validarDTO( local.dto, "criar" );
	}

	private void function validarDTO( required any dto, required string perfil ) {
		local.resultado = variables.validationManager.validate( target = arguments.dto, profiles = arguments.perfil );
		if ( local.resultado.hasErrors() ) {
			throw( type = "CategoriaInvalida", message = local.resultado.getAllErrors()[ 1 ] );
		}
	}

	private struct function paraDados( required any categoria ) {
		return {
			cdCategoria : arguments.categoria.getCdCategoria(),
			txCategoria : arguments.categoria.getTxCategoria(),
			inAtivo : NOT isNull( arguments.categoria.getInAtivo() ) AND arguments.categoria.getInAtivo() EQ true
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
