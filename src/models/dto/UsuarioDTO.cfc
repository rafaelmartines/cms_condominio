component accessors="true" {

	property name="nmUsuario" type="any" default="";
	property name="txEmail" type="any" default="";
	property name="txSenha" type="any" default="";
	property name="txConfirmacaoSenha" type="any" default="";

	this.constraints = {
		nmUsuario : {
			required : true, type : "string", size : "1..100",
			requiredMessage : "Informe seu nome.", typeMessage : "Informe um nome válido.",
			sizeMessage : "O nome deve ter de 1 a 100 caracteres."
		},
		txEmail : {
			required : true, type : "email", size : "1..254",
			requiredMessage : "Informe seu e-mail.", typeMessage : "Informe um e-mail válido.",
			sizeMessage : "O e-mail deve ter até 254 caracteres."
		},
		txSenha : {
			required : true, type : "string", size : "12..128",
			requiredMessage : "Informe sua senha.", typeMessage : "Informe uma senha válida.",
			sizeMessage : "A senha deve ter de 12 a 128 caracteres."
		},
		txConfirmacaoSenha : {
			required : true, type : "string",
			udf : function( value, target, errorMetadata ) {
				return isSimpleValue( arguments.value ) AND isSimpleValue( arguments.target.getTxSenha() ) AND
					compare( arguments.value, arguments.target.getTxSenha() ) EQ 0;
			},
			requiredMessage : "Confirme sua senha.", typeMessage : "Confirme sua senha.",
			udfMessage : "As senhas devem ser iguais."
		}
	};

	this.constraintProfiles = {
		cadastro : "nmUsuario,txEmail,txSenha,txConfirmacaoSenha",
		login : "txEmail,txSenha"
	};

}
