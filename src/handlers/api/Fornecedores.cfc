component extends="coldbox.system.RestHandler" {

	remote any function getFornecedores( event, rc, prc ) renderData="json" {
		param arguments.rc.nmFornecedor = arguments.rc[ "filtroNome" ] ?: "";
		param arguments.rc.cdCategoria  = arguments.rc[ "filtroCategoria" ] ?: "";
		param arguments.rc.orderColumn  = arguments.rc[ "order[0][column]" ] ?: "0";
		param arguments.rc.orderDir     = arguments.rc[ "order[0][dir]" ] ?: "asc";

		local.fornecedoresFiltroDTO = populateModel( "FornecedoresFiltroDTO" );

		return getInstance( "FornecedoresService" ).listarFornecedores( local.fornecedoresFiltroDTO );
	}

	remote any function postTestemunho( event, rc, prc ) renderData="json" {
		local.corpo = deserializeJSON( arguments.event.getHttpContent() );

		local.testemunhoDTO = populateModel( model = "TestemunhoDTO", memento = local.corpo );
		local.testemunhoDTO.setCdFornecedor( arguments.rc.cdFornecedor );

		try {
			return getInstance( "FornecedoresService" ).postTestemunho( local.testemunhoDTO );
		} catch ( ResendException falha ) {
			// Impede que o interceptor tente enviar outro e-mail pela integração que falhou.
			arguments.prc.erroEmailProcessado = true;
			arguments.event.renderData( type = "json", statusCode = 502, data = { error : true, message : local.falha.message } );
		}
	}

	remote any function indicacao( event, rc, prc ) renderData="json" {
		// Nenhum erro deste fluxo deve disparar notificação por e-mail.
		arguments.prc.erroEmailProcessado = true;
		local.conteudo = arguments.event.getHttpContent();
		if ( NOT isJSON( local.conteudo ) ) {
			arguments.event.renderData( type = "json", statusCode = 400, data = { error : true, message : "Envie um objeto JSON válido." } );
			return;
		}
		local.corpo = deserializeJSON( local.conteudo );
		if ( isNull( local.corpo ) OR NOT isStruct( local.corpo ) ) {
			arguments.event.renderData( type = "json", statusCode = 400, data = { error : true, message : "Envie um objeto JSON válido." } );
			return;
		}

		try {
			// Validar tipos antes dos setters tipados evita tratar entrada inválida como erro interno.
			for ( local.campo in [ "nmFornecedor", "nmIndicador", "nrApartamento", "nrWhatsapp", "txMotivo" ] ) {
				if ( NOT structKeyExists( local.corpo, local.campo ) OR NOT isSimpleValue( local.corpo[ local.campo ] ) ) {
					throw( type = "FornecedorInvalido", message = "Preencha os dados obrigatórios da indicação com valores válidos." );
				}
			}
			if ( NOT isArray( local.corpo.categorias ?: "" ) ) {
				throw( type = "FornecedorInvalido", message = "Selecione as categorias do fornecedor." );
			}
			local.corpo.txInstagram = local.corpo.txInstagram ?: "";
			if ( NOT isSimpleValue( local.corpo.txInstagram ) OR ( structKeyExists( local.corpo, "nrNota" ) AND NOT isValid( "numeric", local.corpo.nrNota ) ) ) {
				throw( type = "FornecedorInvalido", message = "Informe Instagram e nota válidos." );
			}
			local.indicacaoDTO = populateModel(
				model = "IndicacaoDTO", memento = local.corpo,
				include = "nmFornecedor,nmIndicador,nrApartamento,nrWhatsapp,txMotivo,categorias,txInstagram,nrNota"
			);
			if ( NOT getInstance( "FornecedoresService" ).postIndicacao( local.indicacaoDTO ) ) {
				throw( type = "IndicacaoNaoRegistrada", message = "Falha ao registrar indicação." );
			}
			arguments.event.renderData( type = "json", statusCode = 201, data = {
				error : false, message : "Indicação registrada com sucesso. O fornecedor está aguardando aprovação."
			} );
		} catch ( FornecedorInvalido falha ) {
			arguments.event.renderData( type = "json", statusCode = 422, data = { error : true, message : local.falha.message } );
		} catch ( any falha ) {
			// Somente tipo e localização: a mensagem bruta pode conter SQL e dados do morador.
			local.diagnostico = { tipo : left( reReplace( local.falha.type, "[^A-Za-z0-9_.]", "", "all" ), 120 ), origem : [] };
			for ( local.frame in ( local.falha.tagContext ?: [] ) ) {
				if ( arrayLen( local.diagnostico.origem ) GTE 10 ) break;
				if ( reFindNoCase( "[/\\](handlers|models)[/\\]", local.frame.template ?: "" ) ) {
					arrayAppend( local.diagnostico.origem, { arquivo : local.frame.template, linha : local.frame.line ?: 0 } );
				}
			}
			log.error( "Falha inesperada ao registrar indicação de fornecedor.", serializeJSON( local.diagnostico ) );
			arguments.event.renderData( type = "json", statusCode = 500, data = { error : true, message : "Não foi possível registrar a indicação. Tente novamente em instantes." } );
		}
	}

}
