component extends="coldbox.system.EventHandler" {
	this.allowedMethods = { getFornecedor : "GET", indicar : "GET", addFornecedor : "GET", criar : "POST", aprovacao : "GET", aprovarFornecedor : "POST" };


	public any function getFornecedor( event, rc, prc ) {
		arguments.prc.fornecedor  = getInstance( "FornecedoresService" ).getFornecedor( arguments.rc.cdFornecedor );
		arguments.prc.titulo      = "Detalhes - #arguments.prc.fornecedor.nmFornecedor#";
		arguments.prc.comentarios = getInstance( "FornecedoresService" ).getComentariosPorFornecedor(
			arguments.rc.cdFornecedor
		);
		arguments.prc.media = getInstance( "FornecedoresService" ).getMedia( arguments.rc.cdFornecedor );
		arguments.event.setView( "fornecedores/fornecedor" );
	}

	public void function indicar( event, rc, prc ) {
		arguments.prc.categorias = getInstance( "CategoriaService" ).obterCategorias();
		arguments.prc.titulo = "Indicar fornecedor";
		arguments.event.setView( "fornecedores/indicar" );
	}

	public void function addFornecedor( event, rc, prc ) secured="true" {
		arguments.prc.dados = { nmFornecedor : "", nmEmpresa : "", nrTelefone : "", txInstagram : "", categorias : [] };
		prepararCadastro( arguments.event, arguments.prc );
	}

	public void function criar( event, rc, prc ) secured="true" {
		if ( NOT validarToken( arguments.event, arguments.rc, arguments.prc ) ) return;
		local.dto = populateModel( model = "FornecedorDTO", include = "nmFornecedor,nmEmpresa,nrTelefone,txInstagram,categorias" );
		getInstance( "FornecedoresService" ).addFornecedor( local.dto );
		flash.put( "fornecedoresMensagem", "Fornecedor cadastrado. Aguarde a aprovação de um administrador." );
		relocate( uri = "/fornecedores/adicionar", statusCode = 303 );
	}

	public void function aprovacao( event, rc, prc ) secured="true" {
		if ( NOT validarAdministrador( arguments.event, arguments.prc ) ) return;
		arguments.prc.titulo = "Aprovação de fornecedores";
		arguments.prc.fornecedores = getInstance( "FornecedoresService" ).listarAguardando();
		arguments.prc.csrfToken = csrfGenerateToken( "fornecedores" );
		arguments.prc.mensagem = flash.get( "fornecedoresMensagem", "" );
		arguments.event.setView( "fornecedores/aprovacao" );
	}

	public void function aprovarFornecedor( event, rc, prc ) secured="true" {
		if ( NOT validarAdministrador( arguments.event, arguments.prc ) ) return;
		if ( NOT validarToken( arguments.event, arguments.rc, arguments.prc ) ) return;
		getInstance( "FornecedoresService" ).aprovarFornecedor( arguments.rc.cdFornecedor ?: "" );
		flash.put( "fornecedoresMensagem", "Fornecedor aprovado e publicado na lista." );
		relocate( uri = "/fornecedores/aprovacao", statusCode = 303 );
	}

	public void function onError( event, rc, prc, faultAction, exception, eventArguments ) {
		if ( listFindNoCase( "InvalidHTTPMethod,TestController.relocate", arguments.exception.type ) ) throw( object = arguments.exception );
		if ( arguments.exception.type EQ "FornecedorInvalido" AND arguments.faultAction EQ "criar" ) {
			arguments.prc.dados = {};
			for ( local.campo in [ "nmFornecedor", "nmEmpresa", "nrTelefone", "txInstagram" ] ) {
				arguments.prc.dados[ local.campo ] = isSimpleValue( arguments.rc[ local.campo ] ?: "" ) ? ( arguments.rc[ local.campo ] ?: "" ) : "";
			}
			local.categorias = arguments.rc.categorias ?: "";
			arguments.prc.dados.categorias = isArray( local.categorias ) ? local.categorias : ( isSimpleValue( local.categorias ) ? listToArray( local.categorias ) : [] );
			arguments.prc.erro = arguments.exception.message;
			arguments.event.setHTTPHeader( statusCode = 422 );
			prepararCadastro( arguments.event, arguments.prc );
			return;
		}
		local.status = 500;
		local.mensagem = "Não foi possível concluir a operação. Tente novamente em instantes.";
		switch ( arguments.exception.type ) {
			case "FornecedorInvalido": local.status = 422; break;
			case "FornecedorNaoEncontrado": local.status = 404; break;
			case "FornecedorNaoAguardando": local.status = 409; break;
		}
		if ( local.status NEQ 500 ) local.mensagem = arguments.exception.message;
		exibirErro( arguments.event, arguments.prc, local.status, local.mensagem );
	}

	private void function prepararCadastro( required any event, required struct prc ) {
		arguments.prc.titulo = "Cadastrar fornecedor";
		arguments.prc.categorias = getInstance( "CategoriaService" ).obterCategorias();
		arguments.prc.csrfToken = csrfGenerateToken( "fornecedores" );
		arguments.prc.mensagem = flash.get( "fornecedoresMensagem", "" );
		param arguments.prc.erro = "";
		arguments.event.setView( "fornecedores/adicionar" );
	}

	private boolean function validarAdministrador( required any event, required struct prc ) {
		// Consulta a permissão atual para que revogações não dependam de um novo login.
		local.usuario = getInstance( "UsuarioService" ).retrieveUserById( auth().getUser().getId() );
		if ( local.usuario.hasPermission( "aprovarFornecedor" ) ) return true;
		exibirErro( arguments.event, arguments.prc, 403, "Somente administradores podem aprovar fornecedores." );
		return false;
	}

	private boolean function validarToken( required any event, required struct rc, required struct prc ) {
		local.token = arguments.rc.csrfToken ?: "";
		if ( isSimpleValue( local.token ) AND len( local.token ) AND csrfVerifyToken( local.token, "fornecedores" ) ) return true;
		exibirErro( arguments.event, arguments.prc, 403, "O formulário expirou ou é inválido. Atualize a página e tente novamente." );
		return false;
	}

	private void function exibirErro( required any event, required struct prc, required numeric status, required string mensagem ) {
		arguments.prc.titulo = "Não foi possível concluir";
		arguments.prc.erro = arguments.mensagem;
		arguments.event.setHTTPHeader( statusCode = arguments.status );
		arguments.event.setView( "fornecedores/erro" );
	}
}
