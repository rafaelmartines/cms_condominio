component extends="coldbox.system.EventHandler" {

	property name="categoriaService" inject="CategoriaService";

	this.allowedMethods = {
		index : "GET", adicionar : "GET", criar : "POST", editar : "GET", confirmarInativacao : "GET", salvar : "POST", inativar : "POST"
	};

	public void function index( event, rc, prc ) {
		prc.titulo = "Categorias de fornecedores";
		prc.categorias = variables.categoriaService.listarParaGestao();
		prc.mensagem = flash.get( "categoriasMensagem", "" );
		event.setView( "categorias/index" );
	}

	public void function adicionar( event, rc, prc ) {
		prc.categoria = { txCategoria : "" };
		prepararFormulario( event, prc, true );
	}

	public void function criar( event, rc, prc ) {
		if ( !validarToken( event, rc, prc ) ) return;
		prc.categoria = { txCategoria : "" };
		variables.categoriaService.criarCategoria( rc.txCategoria ?: "" );
		flash.put( "categoriasMensagem", "Categoria criada com sucesso." );
		relocate( uri = "/categorias", statusCode = 303 );
	}

	public void function editar( event, rc, prc ) {
		prc.categoria = variables.categoriaService.obterCategoria( rc.cdCategoria ?: "" );
		prepararFormulario( event, prc );
	}

	public void function confirmarInativacao( event, rc, prc ) {
		prc.categoria = variables.categoriaService.obterCategoria( rc.cdCategoria ?: "" );
		prc.titulo = "Inativar categoria";
		prc.csrfToken = csrfGenerateToken( "categorias" );
		event.setView( "categorias/inativar" );
	}

	public void function salvar( event, rc, prc ) {
		if ( !validarToken( event, rc, prc ) ) return;
		prc.categoria = variables.categoriaService.obterCategoria( rc.cdCategoria ?: "" );
		variables.categoriaService.editarCategoria( rc.cdCategoria, rc.txCategoria ?: "" );
		flash.put( "categoriasMensagem", "Categoria atualizada com sucesso." );
		relocate( uri = "/categorias", statusCode = 303 );
	}

	public void function inativar( event, rc, prc ) {
		if ( !validarToken( event, rc, prc ) ) return;
		variables.categoriaService.inativarCategoria( rc.cdCategoria ?: "" );
		flash.put( "categoriasMensagem", "Categoria inativada com sucesso." );
		relocate( uri = "/categorias", statusCode = 303 );
	}

	public void function onError( event, rc, prc, faultAction, exception, eventArguments ) {
		if ( arguments.exception.type == "InvalidHTTPMethod" ) {
			throw( object = arguments.exception );
		}
		if (
			( arguments.faultAction == "salvar" || arguments.faultAction == "criar" ) &&
			arguments.exception.type == "CategoriaInvalida" &&
			structKeyExists( arguments.prc, "categoria" )
		) {
			arguments.prc.categoria.txCategoria = isSimpleValue( arguments.rc.txCategoria ?: "" ) ? ( arguments.rc.txCategoria ?: "" ) : "";
			arguments.prc.erroNome = arguments.exception.message;
			arguments.event.setHTTPHeader( statusCode = 422 );
			prepararFormulario( arguments.event, arguments.prc, arguments.faultAction == "criar" );
			return;
		}
		exibirErro( arguments.event, arguments.prc, arguments.exception );
	}

	private void function prepararFormulario( required any event, required struct prc, boolean nova = false ) {
		arguments.prc.titulo = arguments.nova ? "Nova categoria" : "Editar categoria";
		arguments.prc.csrfToken = csrfGenerateToken( "categorias" );
		param arguments.prc.erroNome = "";
		arguments.event.setView( arguments.nova ? "categorias/adicionar" : "categorias/editar" );
	}

	private boolean function validarToken( required any event, required struct rc, required struct prc ) {
		var token = arguments.rc.csrfToken ?: "";
		if ( isSimpleValue( token ) && len( token ) && csrfVerifyToken( token, "categorias" ) ) return true;
		arguments.event.setHTTPHeader( statusCode = 403 );
		arguments.prc.titulo = "Não foi possível concluir";
		arguments.prc.erro = "O formulário expirou ou é inválido. Volte à lista e tente novamente.";
		arguments.event.setView( "categorias/erro" );
		return false;
	}

	private void function exibirErro( required any event, required struct prc, required any erro ) {
		var status = 500;
		arguments.prc.titulo = "Não foi possível concluir";
		arguments.prc.erro = "Não foi possível acessar as categorias. Tente novamente em instantes.";
		if ( arguments.erro.type == "CategoriaNaoEncontrada" ) {
			status = 404;
			arguments.prc.erro = arguments.erro.message;
		} else if ( arguments.erro.type == "CategoriaInvalida" ) {
			status = 422;
			arguments.prc.erro = arguments.erro.message;
		} else {
			log.error( "Falha no gerenciamento de categorias (#arguments.erro.type#)." );
		}
		arguments.event.setHTTPHeader( statusCode = status );
		arguments.event.setView( "categorias/erro" );
	}

}
