<cfoutput>
	<div class="mx-auto" style="max-width: 42rem;">
		<a href="/categorias" class="btn btn-link px-0 mb-3"><i class="bi bi-arrow-left me-2" aria-hidden="true"></i>Voltar às categorias</a>
		<div class="card shadow-sm border-0">
			<div class="card-header py-3 bg-body-secondary"><h1 class="h5 mb-0">Nova categoria</h1></div>
			<div class="card-body">
				<form method="post" action="/categorias/adicionar">
					<div class="mb-4">
						<label for="txCategoria" class="form-label">Nome da categoria</label>
						<input type="text" name="txCategoria" id="txCategoria" class="form-control #len( prc.erroNome ) ? 'is-invalid' : ''#" value="#encodeForHTMLAttribute( prc.categoria.txCategoria )#" maxlength="100" required aria-describedby="ajudaNome erroNome" aria-invalid="#len( prc.erroNome ) ? 'true' : 'false'#">
						<div id="ajudaNome" class="form-text">De 1 a 100 caracteres. A categoria será criada como ativa.</div>
						<div id="erroNome" class="invalid-feedback" role="alert">#encodeForHTML( prc.erroNome )#</div>
					</div>
					<div class="d-flex flex-wrap gap-2">
						<button type="submit" class="btn btn-primary">Criar categoria</button>
						<a href="/categorias" class="btn btn-outline-secondary">Cancelar</a>
					</div>
				</form>
			</div>
		</div>
	</div>
</cfoutput>
