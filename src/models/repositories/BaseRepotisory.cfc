
component singleton {
    
    public BaseRepotisory function init() {
        return this;
    }

    public any consulta(string sql, struct params = {}) {
        return queryExecute(
            sql = sql,
            params = params,
        );
    }
}