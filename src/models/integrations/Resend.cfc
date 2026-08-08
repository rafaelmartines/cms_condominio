component singleton {

	public boolean function enviarEmail( required struct corpoEmail ) {
		structAppend(
			arguments.corpoEmail,
			{
				"from" : application.resendFrom,
				"to"   : application.resendTo
			}
		);

		cfhttp(
			method  = "POST",
			charset = "utf-8",
			url     = application.resendUri,
			result  = "local.resultado"
		) {
			cfhttpparam(
				type  = "header",
				name  = "Authorization",
				value = "Bearer #application.resendKey#"
			);
			cfhttpparam(
				type  = "header",
				name  = "Content-Type",
				value = "application/json"
			);
			cfhttpparam( type = "body", value = serializeJSON( arguments.corpoEmail ) );
		}

		if ( not local.resultado.statusCode contains "200" ) {
			throw(
				type    = "ResendException",
				message = "Falha ao enviar e-mail via Resend API. Código de status: #local.resultado.statusCode#"
			);
		}

		return true;
	}

}
