component extends="coldbox.system.EventHandler" {

	property name="authenticationService" inject="security.JwtAuthenticationService";
	property name="usuarioService" inject="UsuarioService";

	this.allowedMethods = { login : "GET", entrar : "POST", cadastro : "GET", criar : "POST", sair : "POST", boasVindas : "GET", renovar : "POST", token : "GET" };

	public void function login( event, rc, prc ) {
		prepararFormulario( arguments.event, arguments.prc, false );
	}

	public void function naoAutenticado( event, rc, prc ) {
		arguments.event.setHTTPHeader( name = "Cache-Control", value = "no-store" );
		if ( arguments.event.getHTTPMethod() EQ "GET" AND NOT len( arguments.event.getHTTPHeader( "Authorization", "" ) ?: "" ) AND findNoCase( "text/html", arguments.event.getHTTPHeader( "Accept", "" ) ?: "" ) ) {
			arguments.prc.titulo = "Carregando";
			arguments.prc.jwtPendente = true;
			arguments.event.setView( "autenticacao/carregando" );
			return;
		}
		arguments.event.renderData( type = "json", statusCode = 401, data = { "erro" : "Autenticação necessária." } );
	}

	public void function boasVindas( event, rc, prc ) secured="true" {
		arguments.prc.titulo = "Bem-vindo(a)";
		arguments.prc.nmUsuario = variables.authenticationService.getUser().getNmUsuario();
		arguments.event.setHTTPHeader( name = "Cache-Control", value = "no-store" );
		arguments.event.setView( "autenticacao/boasVindas" );
	}

	public void function cadastro( event, rc, prc ) secured="true" {
		prepararFormulario( arguments.event, arguments.prc, true );
	}

	public void function entrar( event, rc, prc ) {
		prepararFormulario( arguments.event, arguments.prc, false );
		if ( findNoCase( "application/json", arguments.event.getHTTPHeader( "Content-Type", "" ) ?: "" ) ) {
			try {
				local.corpo = deserializeJSON( arguments.event.getHTTPContent() );
			} catch ( any erro ) {
				throw( type = "LoginJsonInvalido", message = "Envie um objeto JSON válido com e-mail e senha." );
			}
			if ( isNull( local.corpo ) OR NOT isStruct( local.corpo ) ) {
				throw( type = "LoginJsonInvalido", message = "Envie um objeto JSON válido com e-mail e senha." );
			}
			local.dto = populateModel( model = "UsuarioDTO", memento = local.corpo, include = "txEmail,txSenha" );
		} else {
			local.dto = populateModel( model = "UsuarioDTO", include = "txEmail,txSenha" );
		}
		arguments.prc.dados.txEmail = isSimpleValue( local.dto.getTxEmail() ) ? local.dto.getTxEmail() : "";
		if ( NOT validarFormulario( arguments.event, arguments.prc, local.dto, "login" ) ) return;
		local.usuario = variables.authenticationService.authenticate( lCase( trim( local.dto.getTxEmail() ) ), local.dto.getTxSenha() );
		local.resposta = variables.authenticationService.emitirTokens( local.usuario );
		arguments.event.renderData( type = "json", data = local.resposta );
	}

	public void function token( event, rc, prc ) {
		arguments.event.setHTTPHeader( name = "Cache-Control", value = "no-store" );
		if ( NOT variables.authenticationService.isLoggedIn() ) {
			arguments.event.renderData( type = "json", statusCode = 401, data = { "erro" : "Autenticação necessária." } );
			return;
		}
		arguments.event.renderData( type = "json", data = { "autenticado" : true } );
	}

	public void function renovar( event, rc, prc ) {
		arguments.event.setHTTPHeader( name = "Cache-Control", value = "no-store" );
		try {
			arguments.event.renderData( type = "json", data = variables.authenticationService.renovar() );
		} catch ( any erro ) {
			if ( NOT listFindNoCase( "TokenInvalidException,TokenExpiredException,TokenRejectionException,TokenNotFoundException,UsuarioNaoEncontrado", local.erro.type ) ) throw( object = local.erro );
			arguments.event.renderData( type = "json", statusCode = 401, data = { "erro" : "Seu acesso expirou. Entre novamente." } );
		}
	}

	public void function criar( event, rc, prc ) secured="true" {
		prepararFormulario( arguments.event, arguments.prc, true );
		local.dto = populateModel( model = "UsuarioDTO", include = "nmUsuario,txEmail,txSenha,txConfirmacaoSenha" );
		arguments.prc.dados.nmUsuario = isSimpleValue( local.dto.getNmUsuario() ) ? local.dto.getNmUsuario() : "";
		arguments.prc.dados.txEmail = isSimpleValue( local.dto.getTxEmail() ) ? local.dto.getTxEmail() : "";
		if ( NOT validarFormulario( arguments.event, arguments.prc, local.dto, "cadastro" ) ) return;
		variables.usuarioService.cadastrar( local.dto );
		flash.put( "usuarioMensagem", "Usuário cadastrado com sucesso." );
		relocate( uri = "/cadastro", statusCode = 303 );
	}

	public void function sair( event, rc, prc ) {
		variables.authenticationService.logout();
		sessionInvalidate();
		arguments.event.setHTTPHeader( name = "Cache-Control", value = "no-store" );
		arguments.event.renderData( type = "json", data = { "sucesso" : true } );
	}

	public void function onError( event, rc, prc, faultAction, exception, eventArguments ) {
		arguments.prc.erroNotificacao = arguments.exception;
		if ( arguments.faultAction EQ "entrar" AND arguments.exception.type EQ "InvalidHTTPMethod" ) {
			arguments.event.setHTTPHeader( name = "Allow", value = "POST" );
			arguments.event.renderData( type = "json", statusCode = 405, data = { erro : "Use POST para entrar." } );
			return;
		}
		if ( listFindNoCase( "InvalidHTTPMethod,TestController.relocate", arguments.exception.type ) ) {
			throw( object = arguments.exception );
		}
		if ( NOT structKeyExists( arguments.prc, "dados" ) ) {
			prepararFormulario( arguments.event, arguments.prc, arguments.faultAction EQ "criar" );
		}
		arguments.prc.erro = "Não foi possível concluir a operação. Tente novamente em instantes.";
		local.status = 500;
		if ( arguments.exception.type EQ "LoginJsonInvalido" ) {
			local.status = 400;
			arguments.prc.erro = arguments.exception.message;
		} else if ( arguments.exception.type EQ "InvalidCredentials" ) {
			local.status = 401;
			arguments.prc.erro = "E-mail ou senha inválidos.";
		} else if ( listFindNoCase( "TokenInvalidException,TokenExpiredException,TokenRejectionException,TokenNotFoundException", arguments.exception.type ) ) {
			local.status = 401;
			arguments.prc.erro = "Autenticação necessária.";
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
		if ( arguments.faultAction EQ "entrar" OR arguments.faultAction EQ "renovar" OR arguments.faultAction EQ "sair" OR arguments.faultAction EQ "token" ) {
			arguments.event.renderData( type = "json", statusCode = local.status, data = { "erro" : arguments.prc.erro } );
		}
	}

	private void function prepararFormulario( required any event, required struct prc, required boolean cadastro ) {
		arguments.prc.titulo = arguments.cadastro ? "Cadastrar usuário" : "Entrar";
		arguments.prc.dados = { nmUsuario : "", txEmail : "" };
		arguments.prc.erro = "";
		arguments.prc.mensagem = flash.get( "usuarioMensagem", "" );
		arguments.event.setHTTPHeader( name = "Cache-Control", value = "no-store" );
		arguments.event.setView( arguments.cadastro ? "autenticacao/cadastro" : "autenticacao/login" );
	}


	private boolean function validarFormulario( required any event, required struct prc, required any dto, required string perfil ) {
		local.resultado = validate( target = arguments.dto, profiles = arguments.perfil );
		if ( NOT local.resultado.hasErrors() ) return true;
		arguments.prc.erro = local.resultado.getAllErrors()[ 1 ];
		arguments.event.setHTTPHeader( statusCode = 422 );
		if ( arguments.perfil EQ "login" ) arguments.event.renderData( type = "json", statusCode = 422, data = { "erro" : arguments.prc.erro } );
		return false;
	}

}
