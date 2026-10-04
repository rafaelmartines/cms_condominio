component singleton extends="BaseRepository" {

	property name="categoriaProvider" inject="provider:Categoria";

	public array function listarParaGestao() {
		return variables.categoriaProvider.$get().orderBy( "txCategoria" ).orderBy( "cdCategoria" ).get();
	}

	public any function obterPorId( required numeric cdCategoria ) {
		return variables.categoriaProvider.$get().find( arguments.cdCategoria );
	}

	public void function criar( required string txCategoria ) {
		var instante = now();
		variables.categoriaProvider.$get().create( {
			txCategoria : arguments.txCategoria,
			inAtivo : true,
			tsCriadoEm : instante,
			tsAtualizado : instante
		} );
	}

	public boolean function editar( required numeric cdCategoria, required string txCategoria ) {
		var resultado = variables.categoriaProvider.$get().where( "cdCategoria", arguments.cdCategoria ).updateAll( {
			txCategoria : arguments.txCategoria,
			tsAtualizado : now()
		} );
		return resultado.result.recordCount > 0;
	}

	public boolean function inativar( required numeric cdCategoria ) {
		var resultado = variables.categoriaProvider.$get().where( "cdCategoria", arguments.cdCategoria ).updateAll( {
			inAtivo : false,
			tsAtualizado : now()
		} );
		return resultado.result.recordCount > 0;
	}

	public CategoriaRepository function init() {
		return this;
	}

	public boolean function reativar( required numeric cdCategoria ) {
		local.resultado = variables.categoriaProvider.$get().where( "cdCategoria", arguments.cdCategoria ).updateAll( {
			inAtivo : true,
			tsAtualizado : now()
		} );
		return local.resultado.result.recordCount GT 0;
	}

	public array function obterCategorias() {
		local.sql = "
        SELECT
            c.*
        FROM
            CMSCONDOMINIO.tb_categoria c
        WHERE
            c.in_ativo = TRUE
        ORDER BY
            c.tx_categoria ASC
        ";

		return variables.consulta( local.sql );
	}

}
