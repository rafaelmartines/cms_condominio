component accessors="true" implements="cbsecurity.interfaces.IAuthUser" {

	property name="cdUsuario";
	property name="nmUsuario";
	property name="txEmail";

	public any function init( required struct dados ) {
		variables.cdUsuario = arguments.dados.cd_usuario;
		variables.nmUsuario = arguments.dados.nm_usuario;
		variables.txEmail = arguments.dados.tx_email;
		return this;
	}

	public any function getId() {
		return variables.cdUsuario;
	}

	public boolean function hasPermission( required permission ) {
		return false;
	}

	public boolean function hasRole( required role ) {
		return false;
	}

}
