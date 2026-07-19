component
	displayname="FornecedoresFiltroDTO"
	accessors  ="true"
	output     ="false"
{

	property name="start"     type="numeric"    default="0";
	property
		name   ="length"
		type   ="numeric"
		default="10";
	property name="nmFornecedor" type="string";
	property name="nmEmpresa"    type="string";

	public FornecedoresFiltroDTO function init() {
		return this;
	}

}
