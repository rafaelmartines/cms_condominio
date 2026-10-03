/** JWT recebido exclusivamente pelo header Authorization. */
component singleton implements="cbsecurity.interfaces.IAuthService" {
	property name="usuarioService" inject="UsuarioService";
	property name="jwtProvider" inject="provider:JwtService@cbsecurity";
	property name="requestService" inject="coldbox:requestService";

	public any function authenticate( required username, required password ) {
		if ( NOT variables.usuarioService.isValidCredentials( arguments.username, arguments.password ) ) {
			throw( type = "InvalidCredentials", message = "E-mail ou senha inválidos." );
		}
		return login( variables.usuarioService.retrieveUserByUsername( arguments.username ) );
	}

	public any function login( required user ) {
		variables.requestService.getContext().setPrivateValue( "jwtUsuario", arguments.user );
		return arguments.user;
	}

	public boolean function isLoggedIn() {
		local.event = variables.requestService.getContext();
		if ( local.event.privateValueExists( "jwtVerificado" ) ) return local.event.getPrivateValue( "jwtVerificado" );
		local.event.setPrivateValue( "jwtVerificado", false );
		try {
			local.payload = validar( obterToken(), false );
			login( variables.usuarioService.retrieveUserById( local.payload.sub ) );
			local.event.setPrivateValue( "jwtVerificado", true );
			local.event.setHTTPHeader( name = "Cache-Control", value = "no-store" );
			return true;
		} catch ( any erro ) {
			if ( NOT listFindNoCase( "TokenInvalidException,TokenExpiredException,TokenRejectionException,TokenNotFoundException,UsuarioNaoEncontrado", local.erro.type ) ) throw( object = local.erro );
			return false;
		}
	}

	public any function getUser() {
		if ( NOT isLoggedIn() ) throw( type = "NoUserLoggedIn", message = "Autenticação necessária." );
		return variables.requestService.getContext().getPrivateValue( "jwtUsuario" );
	}

	public string function obterToken() {
		local.header = variables.requestService.getContext().getHTTPHeader( "Authorization", "" ) ?: "";
		if ( NOT len( local.header ) ) throw( type = "TokenNotFoundException", message = "Autenticação necessária." );
		if ( NOT reFindNoCase( "^Bearer [A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$", local.header ) ) {
			throw( type = "TokenInvalidException", message = "Token inválido." );
		}
		return mid( local.header, 8, len( local.header ) );
	}

	public struct function emitirTokens( required any usuario ) {
		local.tokens = variables.jwtProvider.$get().fromUser( user = arguments.usuario, customClaims = { "sid" : createUUID() } );
		registrar( local.tokens );
		return respostaTokens( local.tokens );
	}

	public struct function renovar() {
		local.token = obterToken();
		local.payload = validar( local.token, true );
		lock name="cms.jwt.#hash( local.payload.sid, 'SHA-256' )#" type="exclusive" timeout="10" {
			local.payload = validar( local.token, true );
			local.jwt = variables.jwtProvider.$get();
			local.usuario = variables.usuarioService.retrieveUserById( local.payload.sub );
			local.tokens = local.jwt.fromUser(
				user = local.usuario,
				customClaims = { "sid" : local.payload.sid, "exp" : min( local.payload.exp, local.jwt.toEpoch( dateAdd( "n", 15, now() ) ) ) },
				refreshCustomClaims = { "sid" : local.payload.sid, "exp" : local.payload.exp }
			);
			revogarSessao( local.payload.sid );
			registrar( local.tokens );
		}
		return respostaTokens( local.tokens );
	}

	public any function logout() {
		local.payload = variables.jwtProvider.$get().parseToken( token = obterToken(), storeInContext = false, authenticate = false );
		if ( NOT structKeyExists( local.payload, "sid" ) ) throw( type = "TokenInvalidException", message = "Token inválido." );
		lock name="cms.jwt.#hash( local.payload.sid, 'SHA-256' )#" type="exclusive" timeout="10" {
			revogarSessao( local.payload.sid );
		}
		variables.requestService.getContext().setPrivateValue( "jwtVerificado", false );
		return this;
	}

	private struct function validar( required string token, required boolean refresh ) {
		local.payload = variables.jwtProvider.$get().parseToken( token = arguments.token, storeInContext = false, authenticate = false );
		local.isRefresh = structKeyExists( local.payload, "cbsecurity_refresh" ) AND local.payload.cbsecurity_refresh;
		if ( local.isRefresh NEQ arguments.refresh OR NOT structKeyExists( local.payload, "sid" ) ) {
			throw( type = "TokenInvalidException", message = "Tipo de token inválido." );
		}
		if ( NOT variables.jwtProvider.$get().getTokenStorage().exists( "session_" & local.payload.sid ) ) {
			throw( type = "TokenRejectionException", message = "Acesso encerrado." );
		}
		local.payload.exp = variables.jwtProvider.$get().toEpoch( local.payload.exp );
		return local.payload;
	}

	private void function registrar( required struct tokens ) {
		local.jwt = variables.jwtProvider.$get();
		local.access = local.jwt.decode( arguments.tokens.access_token );
		local.refresh = local.jwt.decode( arguments.tokens.refresh_token );
		local.refresh.iat = local.jwt.toEpoch( local.refresh.iat );
		local.refresh.exp = local.jwt.toEpoch( local.refresh.exp );
		local.registro = { "iat" : local.refresh.iat, "exp" : local.refresh.exp, "accessJti" : local.access.jti, "refreshJti" : local.refresh.jti };
		local.jwt.getTokenStorage().set( key = "session_" & local.refresh.sid, token = "", expiration = max( 1, ceiling( ( local.refresh.exp - local.refresh.iat ) / 60 ) ), payload = local.registro );
	}

	private void function revogarSessao( required string sid ) {
		local.storage = variables.jwtProvider.$get().getTokenStorage();
		local.chave = "session_" & arguments.sid;
		if ( NOT local.storage.exists( local.chave ) ) return;
		local.registro = local.storage.get( local.chave ).payload;
		local.storage.clear( local.registro.accessJti );
		local.storage.clear( local.registro.refreshJti );
		local.storage.clear( local.chave );
	}

	private struct function respostaTokens( required struct tokens ) {
		local.jwt = variables.jwtProvider.$get();
		return {
			"access_token" : arguments.tokens.access_token, "refresh_token" : arguments.tokens.refresh_token,
			"token_type" : "Bearer", "expires_at" : local.jwt.toEpoch( local.jwt.decode( arguments.tokens.access_token ).exp ),
			"refresh_expires_at" : local.jwt.toEpoch( local.jwt.decode( arguments.tokens.refresh_token ).exp )
		};
	}
}
