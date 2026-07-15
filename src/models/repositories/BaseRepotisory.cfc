component singleton {

    public BaseRepotisory function init() {
        return this;
    }

    public any function consulta(
        required string sql,
        struct params = {},
        boolean multiplasLinhas = true,
        string keyColumn
    ) {
        local.resultado = queryExecute(
            arguments.sql,
            arguments.params,
            {returntype: "struct", keyColumn: "CD_FORNECEDOR"}
        );

        if (not arguments.multiplasLinhas) {
            local.resultado = arrayFirst(local.resultado);
        }

        return local.resultado;
    }

}
