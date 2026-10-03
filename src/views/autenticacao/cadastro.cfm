<cfoutput>
	<div class="mx-auto" style="max-width: 30rem;">
		<div class="card shadow-sm border-0">
			<div class="card-body p-4">
				<h1 class="h4 mb-3">Criar conta</h1>
				<cfif len( prc.mensagem )><div class="alert alert-success" role="status">#encodeForHTML( prc.mensagem )#</div></cfif>
				<cfif len( prc.erro )><div class="alert alert-danger" role="alert">#encodeForHTML( prc.erro )#</div></cfif>
				<form method="post" action="/cadastro">
					<div class="mb-3">
						<label for="nmUsuario" class="form-label">Nome</label>
						<input id="nmUsuario" name="nmUsuario" type="text" class="form-control" autocomplete="name" maxlength="100" value="#encodeForHTMLAttribute( prc.dados.nmUsuario )#" required>
					</div>
					<div class="mb-3">
						<label for="txEmail" class="form-label">E-mail</label>
						<input id="txEmail" name="txEmail" type="email" class="form-control" autocomplete="email" maxlength="254" value="#encodeForHTMLAttribute( prc.dados.txEmail )#" required>
					</div>
					<div class="mb-3">
						<label for="txSenha" class="form-label">Senha</label>
						<input id="txSenha" name="txSenha" type="password" class="form-control" autocomplete="new-password" maxlength="128" required>
						<div class="form-text">Use de 12 a 128 caracteres.</div>
					</div>
					<div class="mb-3">
						<label for="txConfirmacaoSenha" class="form-label">Confirmar senha</label>
						<input id="txConfirmacaoSenha" name="txConfirmacaoSenha" type="password" class="form-control" autocomplete="new-password" maxlength="128" required>
					</div>
					<button class="btn btn-primary w-100" type="submit">Criar conta</button>
				</form>
				<p class="mt-3 mb-0"><a href="/categorias">Voltar às categorias</a></p>
			</div>
		</div>
	</div>
</cfoutput>
