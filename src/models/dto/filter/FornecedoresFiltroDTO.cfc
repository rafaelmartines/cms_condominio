component accessors="true" {

	property name="start"     type="numeric"    default="0";
	property
		name   ="length"
		type   ="numeric"
		default="10";
	property name="nmFornecedor" type="string";
	property name="nmEmpresa"    type="string";
	property
		name  ="orderColumn"
		type  ="string"
		getter="false";
	property
		name   ="orderDir"
		type   ="string"
		default="asc";

	public FornecedoresFiltroDTO function init() {
		return this;
	}

	public string function getOrderColumn() {
		switch ( variables.orderColumn ) {
			case "0":
				local.orderColumn = "f.nm_fornecedor";
				break;
			case "1":
				local.orderColumn = "f.nm_empresa";
				break;
			default:
				local.orderColumn = "f.cd_fornecedor";
		}

		return local.orderColumn;
	}

}
