component singleton {

    public FornecedoresRepository function init() {
        return this;
    }

    public array function getFornecedores() {
        local.sql = "SELECT * FROM CMSCONDOMINIO.TB_FORNECEDORES";

        local.resultado = queryExecute(
            sql = local.sql
        );

        writeDump(local.resultado);
        abort;
    }

}
