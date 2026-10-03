component {
	function configure() {
		local.segredo = getSystemSetting( "JWT_SECRET", "" );
		local.desenvolvimento = getSystemSetting( "ENVIRONMENT", "production" ) EQ "development";
		if ( ( NOT local.desenvolvimento OR len( local.segredo ) ) AND len( local.segredo ) LT 32 ) {
			throw( type = "ConfiguracaoJWTInvalida", message = "Configure JWT_SECRET com pelo menos 32 caracteres aleatórios." );
		}
		return {
			authentication : { provider : "security.JwtAuthenticationService", userService : "UsuarioService" },
			jwt : {
				issuer : "cms-condominio", secretKey : local.segredo, algorithm : "HS256",
				expiration : 15, enableRefreshTokens : true, refreshExpiration : 10080,
				enableAutoRefreshValidator : false, enableRefreshEndpoint : false,
				tokenStorage : { enabled : true, driver : "cachebox", properties : { cacheName : "default" } }
			},
			firewall : {
				autoLoadFirewall : true,
				validator : "security.AnotacaoAuthValidator",
				invalidAuthenticationEvent : "Autenticacao.naoAutenticado",
				defaultAuthenticationAction : "override"
			}
		};
	}
}
