component accessors="true" implements="cbsecurity.interfaces.IAuthUser" {

	property name="cdUsuario";
	property name="nmUsuario";
	property name="txEmail";

	public any function init( required struct dados ) {
		variables.inAdministrador = structKeyExists( arguments.dados, "in_administrador" ) AND arguments.dados.in_administrador;
		variables.cdUsuario = arguments.dados.cd_usuario;
		variables.nmUsuario = arguments.dados.nm_usuario;
		variables.txEmail = arguments.dados.tx_email;
		return this;
	}

	public any function getId() {
		return variables.cdUsuario;
	}

	public boolean function hasPermission( required permission ) {
		return variables.inAdministrador AND arguments.permission EQ "aprovarFornecedor";
	}

	public boolean function hasRole( required role ) {
		return variables.inAdministrador AND arguments.role EQ "administrador";
	}

}
