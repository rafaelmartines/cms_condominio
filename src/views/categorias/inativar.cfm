<cfoutput>
	<div class="mx-auto" style="max-width: 42rem;">
		<a href="/categorias" class="btn btn-link px-0 mb-3"><i class="bi bi-arrow-left me-2" aria-hidden="true"></i>Voltar às categorias</a>
		<div class="card shadow-sm border-0">
			<div class="card-header py-3 bg-body-secondary"><h1 class="h5 mb-0">Inativar categoria</h1></div>
			<div class="card-body">
				<cfif prc.categoria.inAtivo>
					<p>Deseja inativar <strong>#encodeForHTML( prc.categoria.txCategoria )#</strong>?</p>
					<p class="text-body-secondary">Ela deixará de aparecer nas opções dos formulários e filtros. Os vínculos existentes com fornecedores serão preservados.</p>
					<form method="post" action="/categorias/#prc.categoria.cdCategoria#/inativar" class="d-flex flex-wrap gap-2">
						<button type="submit" class="btn btn-danger">Confirmar inativação</button>
						<a href="/categorias" class="btn btn-outline-secondary">Cancelar</a>
					</form>
				<cfelse>
					<div class="alert alert-info mb-0" role="status">Esta categoria já está inativa.</div>
				</cfif>
			</div>
		</div>
	</div>
</cfoutput>
