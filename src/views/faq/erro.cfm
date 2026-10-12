<cfoutput>
	<div class="alert alert-danger" role="alert">#encodeForHTML( prc.erro )#</div>
	<a href="/faq" class="btn btn-outline-secondary">Voltar ao FAQ público</a>
	<cfif getInstance( "security.JwtAuthenticationService" ).isLoggedIn()><a href="/administracao/faq" class="btn btn-outline-primary">Gerenciar perguntas</a></cfif>
</cfoutput>
