component singleton extends="BaseRepository" {

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
