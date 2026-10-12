<cfoutput>
	<div class="mx-auto" style="max-width: 42rem;">
		<h1 class="h3">Excluir pergunta</h1>
		<p>Deseja retirar esta pergunta do FAQ público? Ela será mantida na administração para permitir a reativação.</p>
		<div class="card mb-3"><div class="card-body text-break">#encodeForHTML( prc.pergunta.txPergunta )#</div></div>
		<form method="post" action="/administracao/faq/#prc.pergunta.cdFaq#/excluir" class="d-flex flex-wrap gap-2">
			<button type="submit" class="btn btn-danger">Confirmar exclusão</button>
			<a href="/administracao/faq" class="btn btn-outline-secondary">Cancelar</a>
		</form>
	</div>
</cfoutput>
