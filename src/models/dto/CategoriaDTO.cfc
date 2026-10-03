component accessors="true" {

	property name="cdCategoria" type="any" default="";
	property name="txCategoria" type="any" default="";

	this.constraints = {
		txCategoria : {
			required : true,
			type : "string",
			size : "1..100",
			requiredMessage : "Informe um nome de categoria com 1 a 100 caracteres.",
			typeMessage : "Informe um nome de categoria com 1 a 100 caracteres.",
			sizeMessage : "Informe um nome de categoria com 1 a 100 caracteres."
		}
	};

	this.constraintProfiles = {
		criar : "txCategoria",
		editar : "txCategoria"
	};

}
