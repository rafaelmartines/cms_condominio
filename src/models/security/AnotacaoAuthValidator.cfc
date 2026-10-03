/** Compatibilidade com cbSecurity 3.8: secured=true exige apenas autenticação. */
component extends="cbsecurity.models.validators.AuthValidator" singleton {

	public struct function annotationValidator( required securedValue, required controller ) {
		return super.annotationValidator(
			securedValue = isBoolean( arguments.securedValue ) AND arguments.securedValue ? "" : arguments.securedValue,
			controller = arguments.controller
		);
	}

}
