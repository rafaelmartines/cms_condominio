component extends="coldbox.system.EventHandler" secured="true" {

	property name      ="faqService" inject="FaqService";
	this.allowedMethods= {
		index             : "GET",
		adicionar         : "GET",
		criar             : "POST",
		editar            : "GET",
		salvar            : "POST",
		confirmarExclusao : "GET",
		excluir           : "POST",
		reativar          : "POST"
	};

	public void function index( event, rc, prc ) {
		arguments.prc.titulo    = "Gerenciar perguntas frequentes";
		arguments.prc.perguntas = variables.faqService.listarParaGestao();
		arguments.prc.mensagem  = flash.get( "faqMensagem", "" );
		arguments.event.setView( "faq/admin/index" );
	}

	public void function adicionar( event, rc, prc ) {
		arguments.prc.pergunta = {
			txPergunta : "",
			txResposta : "",
			inAtivo    : true
		};
		prepararFormulario( arguments.event, arguments.prc, true );
	}

	public void function criar( event, rc, prc ) {
		local.dto = populateModel( model = "FaqDTO", include = "txPergunta,txResposta" );
		variables.faqService.criar( local.dto );
		concluir( "Pergunta criada com sucesso." );
	}

	public void function editar( event, rc, prc ) {
		arguments.prc.pergunta = variables.faqService.obterPergunta( arguments.rc.cdFaq ?: "" );
		prepararFormulario(
			arguments.event,
			arguments.prc,
			false
		);
	}

	public void function salvar( event, rc, prc ) {
		arguments.prc.pergunta = variables.faqService.obterPergunta( arguments.rc.cdFaq ?: "" );
		local.dto              = populateModel( model = "FaqDTO", include = "txPergunta,txResposta" );
		variables.faqService.editar( arguments.rc.cdFaq, local.dto );
		concluir( "Pergunta atualizada com sucesso." );
	}

	public void function confirmarExclusao( event, rc, prc ) {
		arguments.prc.titulo   = "Excluir pergunta";
		arguments.prc.pergunta = variables.faqService.obterPergunta( arguments.rc.cdFaq ?: "" );
		arguments.event.setView( "faq/admin/excluir" );
	}

	public void function excluir( event, rc, prc ) {
		variables.faqService.excluir( arguments.rc.cdFaq ?: "" );
		concluir( "Pergunta excluída do FAQ público. Você pode reativá-la a qualquer momento." );
	}

	public void function reativar( event, rc, prc ) {
		variables.faqService.reativar( arguments.rc.cdFaq ?: "" );
		concluir( "Pergunta reativada com sucesso." );
	}

	public void function onError(
		event,
		rc,
		prc,
		faultAction,
		exception,
		eventArguments
	) {
		arguments.prc.erroNotificacao = arguments.exception;
		if (
			arguments.exception.type EQ "FaqInvalido" AND (
				arguments.faultAction EQ "criar" OR arguments.faultAction EQ "salvar"
			) AND ( arguments.faultAction EQ "criar" OR structKeyExists( arguments.prc, "pergunta" ) )
		) {
			param arguments.prc.pergunta      = { inAtivo : true };
			arguments.prc.pergunta.txPergunta = isSimpleValue( arguments.rc.txPergunta ?: "" ) ? (
				arguments.rc.txPergunta ?: ""
			) : "";
			arguments.prc.pergunta.txResposta = isSimpleValue( arguments.rc.txResposta ?: "" ) ? (
				arguments.rc.txResposta ?: ""
			) : "";
			arguments.prc.erroFormulario = arguments.exception.message;
			arguments.event.setHTTPHeader( statusCode = 422 );
			prepararFormulario(
				arguments.event,
				arguments.prc,
				arguments.faultAction EQ "criar"
			);
			return;
		}
		local.status         = 500;
		arguments.prc.titulo = "Não foi possível concluir";
		arguments.prc.erro   = "Não foi possível acessar as perguntas. Tente novamente em instantes.";
		if ( arguments.exception.type EQ "FaqNaoEncontrado" ) local.status = 404;
		if ( arguments.exception.type EQ "FaqInvalido" ) local.status = 422;
		if ( local.status EQ 404 OR local.status EQ 422 ) arguments.prc.erro = arguments.exception.message;
		if ( arguments.exception.type EQ "InvalidHTTPMethod" ) {
			local.status       = 405;
			arguments.prc.erro = "Método HTTP não permitido para esta operação.";
			arguments.event.setHTTPHeader( name = "Allow", value = this.allowedMethods[ arguments.faultAction ] );
		}
		arguments.event.setHTTPHeader( statusCode = local.status );
		arguments.event.setView( "faq/erro" );
	}

	private void function prepararFormulario(
		required any event,
		required struct prc,
		required boolean nova
	) {
		arguments.prc.novaPergunta         = arguments.nova;
		arguments.prc.titulo               = arguments.nova ? "Nova pergunta" : "Editar pergunta";
		param arguments.prc.erroFormulario = "";
		arguments.event.setView( "faq/admin/formulario" );
	}

	private void function concluir( required string mensagem ) {
		flash.put( "faqMensagem", arguments.mensagem );
		relocate( uri = "/administracao/faq", statusCode = 303 );
	}

}
