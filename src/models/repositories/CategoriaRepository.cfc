component singleton extends="BaseRepository" {

	property name="categoriaProvider" inject="provider:Categoria";

	public array function listarParaGestao() {
		return variables.categoriaProvider.$get().orderBy( "txCategoria" ).orderBy( "cdCategoria" ).get();
	}

	public any function obterPorId( required numeric cdCategoria ) {
		return variables.categoriaProvider.$get().find( arguments.cdCategoria );
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
