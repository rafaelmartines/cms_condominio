component extends="coldbox.system.EventHandler" {

	property name="authenticationService" inject="authenticationService@cbauth";
	property name="usuarioService" inject="UsuarioService";

	this.allowedMethods = { login : "GET", entrar : "POST", cadastro : "GET", criar : "POST", sair : "POST" };

	public void function login( event, rc, prc ) {
		prepararFormulario( arguments.event, arguments.prc, false );
	}

	public void function cadastro( event, rc, prc ) secured="true" {
		prepararFormulario( arguments.event, arguments.prc, true );
	}

	public void function entrar( event, rc, prc ) {
		prepararFormulario( arguments.event, arguments.prc, false );
		if ( NOT validarToken( arguments.event, arguments.rc, arguments.prc ) ) return;
		local.dto = populateModel( model = "UsuarioDTO", include = "txEmail,txSenha" );
		arguments.prc.dados.txEmail = isSimpleValue( local.dto.getTxEmail() ) ? local.dto.getTxEmail() : "";
		if ( NOT validarFormulario( arguments.event, arguments.prc, local.dto, "login" ) ) return;
		variables.authenticationService.authenticate( lCase( trim( local.dto.getTxEmail() ) ), local.dto.getTxSenha() );
		sessionRotate();
		csrfGenerateToken( "autenticacao", true );
		relocate( uri = "/categorias", statusCode = 303 );
	}

	public void function criar( event, rc, prc ) secured="true" {
		prepararFormulario( arguments.event, arguments.prc, true );
		if ( NOT validarToken( arguments.event, arguments.rc, arguments.prc ) ) return;
		local.dto = populateModel( model = "UsuarioDTO", include = "nmUsuario,txEmail,txSenha,txConfirmacaoSenha" );
		arguments.prc.dados.nmUsuario = isSimpleValue( local.dto.getNmUsuario() ) ? local.dto.getNmUsuario() : "";
		arguments.prc.dados.txEmail = isSimpleValue( local.dto.getTxEmail() ) ? local.dto.getTxEmail() : "";
		if ( NOT validarFormulario( arguments.event, arguments.prc, local.dto, "cadastro" ) ) return;
		variables.usuarioService.cadastrar( local.dto );
		flash.put( "usuarioMensagem", "Usuário cadastrado com sucesso." );
		relocate( uri = "/cadastro", statusCode = 303 );
	}

	public void function sair( event, rc, prc ) secured="true" {
		prepararFormulario( arguments.event, arguments.prc, false );
		if ( NOT validarToken( arguments.event, arguments.rc, arguments.prc ) ) return;
		variables.authenticationService.logout();
		sessionInvalidate();
		relocate( uri = "/login", statusCode = 303 );
	}

	public void function onError( event, rc, prc, faultAction, exception, eventArguments ) {
		if ( listFindNoCase( "InvalidHTTPMethod,TestController.relocate", arguments.exception.type ) ) {
			throw( object = arguments.exception );
		}
		if ( NOT structKeyExists( arguments.prc, "dados" ) ) {
			prepararFormulario( arguments.event, arguments.prc, arguments.faultAction EQ "criar" );
		}
		arguments.prc.erro = "Não foi possível concluir a operação. Tente novamente em instantes.";
		local.status = 500;
		if ( arguments.exception.type EQ "InvalidCredentials" ) {
			local.status = 401;
			arguments.prc.erro = "E-mail ou senha inválidos.";
		} else if ( arguments.exception.type EQ "UsuarioDuplicado" ) {
			local.status = 409;
			arguments.prc.erro = arguments.exception.message;
		} else if ( arguments.exception.type EQ "UsuarioInvalido" ) {
			local.status = 422;
			arguments.prc.erro = arguments.exception.message;
		} else {
			log.error( "Falha na autenticação ou cadastro (#arguments.exception.type#)." );
		}
		arguments.event.setHTTPHeader( statusCode = local.status );
	}

	private void function prepararFormulario( required any event, required struct prc, required boolean cadastro ) {
		arguments.prc.titulo = arguments.cadastro ? "Cadastrar usuário" : "Entrar";
		arguments.prc.dados = { nmUsuario : "", txEmail : "" };
		arguments.prc.erro = "";
		arguments.prc.mensagem = flash.get( "usuarioMensagem", "" );
		arguments.prc.csrfToken = csrfGenerateToken( "autenticacao" );
		arguments.event.setHTTPHeader( name = "Cache-Control", value = "no-store" );
		arguments.event.setView( arguments.cadastro ? "autenticacao/cadastro" : "autenticacao/login" );
	}

	private boolean function validarToken( required any event, required struct rc, required struct prc ) {
		local.token = arguments.rc.csrfToken ?: "";
		if ( isSimpleValue( local.token ) AND len( local.token ) AND csrfVerifyToken( local.token, "autenticacao" ) ) return true;
		arguments.prc.erro = "O formulário expirou ou é inválido. Atualize a página e tente novamente.";
		arguments.event.setHTTPHeader( statusCode = 403 );
		return false;
	}

	private boolean function validarFormulario( required any event, required struct prc, required any dto, required string perfil ) {
		local.resultado = validate( target = arguments.dto, profiles = arguments.perfil );
		if ( NOT local.resultado.hasErrors() ) return true;
		arguments.prc.erro = local.resultado.getAllErrors()[ 1 ];
		arguments.event.setHTTPHeader( statusCode = 422 );
		return false;
	}

}
