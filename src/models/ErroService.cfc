component singleton {
	property name="resend" inject="integrations.Resend";
	property name="log" inject="logbox:logger:{this}";

	public void function notificar( required any event, required numeric status, struct exception = {} ) {
		local.prc = arguments.event.getPrivateCollection();
		if ( local.prc.erroEmailProcessado ?: false ) return;
		// Marcar antes do envio impede duplicação e recursão quando o Resend falha.
		local.prc.erroEmailProcessado = true;
		try {
			local.id = createUUID();
			local.registro = {
				"id" : local.id, "data" : dateTimeFormat( now(), "yyyy-mm-dd HH:nn:ss" ),
				"status" : arguments.status, "evento" : arguments.event.getCurrentEvent(),
				"metodo" : arguments.event.getHTTPMethod(), "tipo" : arguments.exception.type ?: "ErroHTTP",
				"pilha" : []
			};
			// Somente localização: mensagens, SQL, headers e conteúdo da requisição podem conter segredos.
			for ( local.frame in ( arguments.exception.tagContext ?: [] ) ) {
				if ( arrayLen( local.registro.pilha ) GTE 50 ) break;
				arrayAppend( local.registro.pilha, { "arquivo" : local.frame.template ?: "", "linha" : local.frame.line ?: 0 } );
			}
			local.conteudo = serializeJSON( local.registro );
			variables.log.error( "Erro da aplicação; registro #local.id#.", local.conteudo );
			variables.resend.enviarEmail( {
				"subject" : "CMS Condomínio: erro HTTP #arguments.status#",
				"text" : "Ocorreu um erro na aplicação. Consulte o log anexado. Registro: #local.id#.",
				"attachments" : [ { "filename" : "erro-#local.id#.log", "content" : toBase64( local.conteudo, "UTF-8" ) } ]
			} );
		} catch ( any falha ) {
			// Não lançar nem notificar esta exceção: preservar o erro original.
			variables.log.error( "Falha ao enviar notificação de erro via Resend (#local.falha.type#)." );
		}
	}
}
