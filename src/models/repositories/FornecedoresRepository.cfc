component singleton extends="BaseRepotisory" {

    property name="cbpaginator" inject="Pagination@cbpaginator";

    public FornecedoresRepository function init() {
        super.init();
        return this;
    }

    public struct function getFornecedores() {
        local.sql = "SELECT f.* FROM CMSCONDOMINIO.TB_FORNECEDORES f";

        local.resultado = variables.consulta(local.sql, {}, true, "CD_FORNECEDOR");

        return cbpaginator.reduceAndGenerate(local.resultado, 0, 10);
    }

}
