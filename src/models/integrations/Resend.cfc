component singleton {
	property name="log" inject="logbox:logger:{this}";

	public boolean function enviarEmail( required struct corpoEmail ) {
		local.config = obterConfiguracao();
		local.payload = duplicate( arguments.corpoEmail );
		local.falhas = [];

		// O remetente configurado é a identidade autorizada; o chamador não a substitui.
		local.payload[ "from" ] = local.config.from;
		if ( NOT enderecoValido( local.config.from ) ) arrayAppend( local.falhas, "from" );
		local.dominio = listLast( reReplace( local.config.from, "^.*<([^<>]+)>$", "\1" ), "@" );
		if ( NOT len( local.config.dominio ) OR compareNoCase( local.dominio, local.config.dominio ) NEQ 0 ) {
			arrayAppend( local.falhas, "RESEND_VERIFIED_DOMAIN" );
		}

		local.padrao = destinatarios( local.config.to );
		local.destinos = destinatarios( local.payload.to ?: local.config.to );
		local.substituto = "";
		for ( local.endereco in local.padrao ) {
			if ( enderecoValido( local.endereco ) ) {
				local.substituto = trim( local.endereco );
				break;
			}
		}
		local.payload[ "to" ] = [];
		for ( local.endereco in local.destinos ) {
			if ( enderecoValido( local.endereco ) ) {
				arrayAppend( local.payload.to, trim( local.endereco ) );
			} else if ( len( local.substituto ) ) {
				arrayAppend( local.payload.to, local.substituto );
			} else {
				arrayAppend( local.falhas, "to" );
			}
		}
		if ( NOT arrayLen( local.payload.to ) OR arrayLen( local.payload.to ) GT 50 ) arrayAppend( local.falhas, "to" );
		for ( local.campo in [ "cc", "bcc", "reply_to" ] ) {
			if ( structKeyExists( local.payload, local.campo ) ) {
				local.lista = destinatarios( local.payload[ local.campo ] );
				if ( NOT arrayLen( local.lista ) ) arrayAppend( local.falhas, local.campo );
				local.payload[ local.campo ] = [];
				for ( local.endereco in local.lista ) {
					if ( enderecoValido( local.endereco ) ) {
						arrayAppend( local.payload[ local.campo ], trim( local.endereco ) );
					} else if ( len( local.substituto ) ) {
						arrayAppend( local.payload[ local.campo ], local.substituto );
					} else {
						arrayAppend( local.falhas, local.campo );
					}
				}
			}
		}
		if ( NOT textoPresente( local.payload, "subject" ) ) arrayAppend( local.falhas, "subject" );
		if ( NOT textoPresente( local.payload, "html" ) AND NOT textoPresente( local.payload, "text" ) ) {
			arrayAppend( local.falhas, "html/text" );
		}
		for ( local.campo in [ "html", "text" ] ) {
			if ( structKeyExists( local.payload, local.campo ) AND NOT isSimpleValue( local.payload[ local.campo ] ) ) {
				arrayAppend( local.falhas, local.campo );
			}
		}
		if ( NOT len( local.config.key ) ) arrayAppend( local.falhas, "RESEND_KEY" );
		if ( local.config.uri NEQ "https://api.resend.com/emails" ) arrayAppend( local.falhas, "RESEND_URI" );
		if ( arrayLen( local.falhas ) ) {
			registrarPayloadInvalido( local.payload, 0, local.falhas );
			throw( type = "ResendException", message = "Não foi possível enviar o e-mail: configuração ou conteúdo inválido. Contate a administração. Não houve reenvio automático." );
		}

		try {
			local.resultado = executarRequisicao( payload = local.payload, config = local.config );
		} catch ( any falha ) {
			variables.log.error( "Resend: falha de comunicação; nenhuma nova tentativa automática." );
			throw( type = "ResendException", message = "Não foi possível confirmar o envio do e-mail. Contate a administração. Não houve reenvio automático." );
		}
		local.status = val( local.resultado.statusCode ?: "0" );
		if ( local.status EQ 422 ) {
			registrarPayloadInvalido( local.payload, 422, [] );
			throw( type = "ResendException", message = "O serviço de e-mail recusou a mensagem por dados inválidos. Contate a administração. Não houve reenvio automático." );
		}
		if ( local.status EQ 403 AND compareNoCase( local.config.dominio, "resend.dev" ) EQ 0 ) {
			variables.log.error( "Resend: envio recusado (HTTP 403) usando domínio de testes; nenhuma nova tentativa automática." );
			throw( type = "ResendException", message = "O envio com resend.dev foi recusado. Esse domínio permite somente o destinatário da própria conta Resend. Contate a administração para configurar um domínio próprio verificado. Não houve reenvio automático." );
		}
		if ( local.status LT 200 OR local.status GTE 300 ) {
			variables.log.error( "Resend: envio recusado (HTTP #local.status#); nenhuma nova tentativa automática." );
			throw( type = "ResendException", message = "O serviço de e-mail não aceitou a mensagem. Contate a administração. Não houve reenvio automático." );
		}
		return true;
	}

	public struct function obterConfiguracao() {
		return {
			from : trim( application.resendFrom ?: "" ), to : application.resendTo ?: "",
			key : trim( application.resendKey ?: "" ), uri : trim( application.resendUri ?: "" ),
			dominio : trim( application.resendVerifiedDomain ?: "" )
		};
	}

	public struct function executarRequisicao( required struct payload, required struct config ) {
		cfhttp( method = "POST", charset = "utf-8", timeout = 10, redirect = false,
			throwOnError = false, url = arguments.config.uri, result = "local.resultado" ) {
			cfhttpparam( type = "header", name = "Authorization", value = "Bearer #arguments.config.key#" );
			cfhttpparam( type = "header", name = "Content-Type", value = "application/json" );
			cfhttpparam( type = "body", value = serializeJSON( arguments.payload ) );
		}
		return local.resultado;
	}

	private boolean function textoPresente( required struct payload, required string campo ) {
		return structKeyExists( arguments.payload, arguments.campo )
			AND isSimpleValue( arguments.payload[ arguments.campo ] ) AND len( trim( arguments.payload[ arguments.campo ] ) ) GT 0;
	}

	private boolean function enderecoValido( required any endereco ) {
		if ( NOT isSimpleValue( arguments.endereco ) OR reFind( "[\r\n]", arguments.endereco ) ) return false;
		local.email = trim( arguments.endereco );
		if ( reFind( "^[^<>]+<[^<>]+>$", local.email ) ) local.email = reReplace( local.email, "^.*<([^<>]+)>$", "\1" );
		return isValid( "email", local.email );
	}

	private array function destinatarios( required any valor ) {
		if ( isArray( arguments.valor ) ) return arguments.valor;
		if ( isSimpleValue( arguments.valor ) ) return listToArray( arguments.valor, ",", true );
		return [];
	}

	private void function registrarPayloadInvalido( required struct payload, required numeric status, required array campos ) {
		// Registrar somente a estrutura: endereços, assunto, conteúdo e anexos contêm dados pessoais.
		local.presentes = [];
		for ( local.campo in [ "from", "to", "subject", "html", "text", "cc", "bcc", "reply_to", "attachments" ] ) {
			if ( structKeyExists( arguments.payload, local.campo ) ) arrayAppend( local.presentes, local.campo );
		}
		variables.log.error( "Resend: payload inválido; envio interrompido.", serializeJSON( {
			status : arguments.status, camposInvalidos : arguments.campos,
			camposPresentes : local.presentes,
			totalDestinatarios : isArray( arguments.payload.to ?: "" ) ? arrayLen( arguments.payload.to ) : 0,
			temAssunto : textoPresente( arguments.payload, "subject" ),
			temHTML : textoPresente( arguments.payload, "html" ), temTexto : textoPresente( arguments.payload, "text" )
		} ) );
	}
}
