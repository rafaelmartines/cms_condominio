component singleton {

	public any function enviarEmail( required struct corpoEmail ) {
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
			result  = "result"
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

		writeDump( var = result, label = "Resend API Response" );
		abort;
	}

}
