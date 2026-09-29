component {
	function configure() {
		return {
			authentication : { provider : "authenticationService@cbauth", userService : "UsuarioService" },
			firewall : {
				autoLoadFirewall : true,
				validator : "security.AnotacaoAuthValidator",
				invalidAuthenticationEvent : "login",
				defaultAuthenticationAction : "redirect"
			}
		};
	}
}
