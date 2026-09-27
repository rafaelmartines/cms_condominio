component extends="coldbox.system.EventHandler" {

	property name="categoriaService" inject="CategoriaService";

	this.allowedMethods = {
		index : "GET", editar : "GET", confirmarInativacao : "GET", salvar : "POST", inativar : "POST"
	};

	public void function index( event, rc, prc ) {
		prc.titulo = "Categorias de fornecedores";
		try {
			prc.categorias = variables.categoriaService.listarParaGestao();
			prc.mensagem = flash.get( "categoriasMensagem", "" );
			event.setView( "categorias/index" );
		} catch ( any erro ) {
			exibirErro( event, prc, erro );
		}
	}

	public void function editar( event, rc, prc ) {
		try {
			prc.categoria = variables.categoriaService.obterCategoria( rc.cdCategoria ?: "" );
			prepararFormulario( event, prc );
		} catch ( any erro ) {
			exibirErro( event, prc, erro );
		}
	}

	public void function confirmarInativacao( event, rc, prc ) {
		try {
			prc.categoria = variables.categoriaService.obterCategoria( rc.cdCategoria ?: "" );
			prc.titulo = "Inativar categoria";
			prc.csrfToken = csrfGenerateToken( "categorias" );
			event.setView( "categorias/inativar" );
		} catch ( any erro ) {
			exibirErro( event, prc, erro );
		}
	}

	public void function salvar( event, rc, prc ) {
		if ( !validarToken( event, rc, prc ) ) return;
		try {
			prc.categoria = variables.categoriaService.obterCategoria( rc.cdCategoria ?: "" );
			variables.categoriaService.editarCategoria( rc.cdCategoria, rc.txCategoria ?: "" );
		} catch ( CategoriaInvalida erro ) {
			if ( !structKeyExists( prc, "categoria" ) ) {
				exibirErro( event, prc, erro );
				return;
			}
			prc.categoria.txCategoria = isSimpleValue( rc.txCategoria ?: "" ) ? ( rc.txCategoria ?: "" ) : "";
			prc.erroNome = erro.message;
			event.setHTTPHeader( statusCode = 422 );
			prepararFormulario( event, prc );
			return;
		} catch ( any erro ) {
			exibirErro( event, prc, erro );
			return;
		}
		flash.put( "categoriasMensagem", "Categoria atualizada com sucesso." );
		relocate( uri = "/categorias", statusCode = 303 );
	}

	public void function inativar( event, rc, prc ) {
		if ( !validarToken( event, rc, prc ) ) return;
		try {
			variables.categoriaService.inativarCategoria( rc.cdCategoria ?: "" );
		} catch ( any erro ) {
			exibirErro( event, prc, erro );
			return;
		}
		flash.put( "categoriasMensagem", "Categoria inativada com sucesso." );
		relocate( uri = "/categorias", statusCode = 303 );
	}

	private void function prepararFormulario( required any event, required struct prc ) {
		arguments.prc.titulo = "Editar categoria";
		arguments.prc.csrfToken = csrfGenerateToken( "categorias" );
		param arguments.prc.erroNome = "";
		arguments.event.setView( "categorias/editar" );
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
