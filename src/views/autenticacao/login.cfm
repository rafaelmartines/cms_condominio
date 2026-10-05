<cfoutput>
	<div class="mx-auto" style="max-width: 30rem;">
		<div class="card shadow-sm border-0">
			<div class="card-body p-4">
				<h1 class="h4 mb-3">Entrar</h1>
				<cfif len( prc.mensagem )><div class="alert alert-success" role="status">#encodeForHTML( prc.mensagem )#</div></cfif>
				<cfif len( prc.erro )><div class="alert alert-danger" role="alert">#encodeForHTML( prc.erro )#</div></cfif>
				<div id="loginErro" class="alert alert-danger d-none" role="alert"></div>
				<form method="post" action="/auth" data-jwt-login>
					<div class="mb-3">
						<label for="txEmail" class="form-label">E-mail</label>
						<input id="txEmail" name="txEmail" type="email" class="form-control" autocomplete="email" maxlength="254" value="#encodeForHTMLAttribute( prc.dados.txEmail )#" required>
					</div>
					<div class="mb-3">
						<label for="txSenha" class="form-label">Senha</label>
						<input id="txSenha" name="txSenha" type="password" class="form-control" autocomplete="current-password" maxlength="128" required>
					</div>
					<button class="btn btn-primary w-100" type="submit">Entrar</button>
				</form>
				<p class="mt-3 mb-0 text-body-secondary">Solicite seu cadastro a um usuário responsável pelo sistema.</p>
			</div>
		</div>
	</div>
</cfoutput>
