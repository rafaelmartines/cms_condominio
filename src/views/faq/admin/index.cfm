<cfoutput>
	<div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-3">
		<h1 class="h3 mb-0">Gerenciar perguntas frequentes</h1>
		<div class="d-flex flex-wrap gap-2">
			<a href="/faq" class="btn btn-outline-secondary">Ver FAQ público</a>
			<a href="/administracao/faq/adicionar" class="btn btn-primary"><i class="bi bi-plus-lg me-2" aria-hidden="true"></i>Nova pergunta</a>
		</div>
	</div>
	<p class="text-body-secondary">Perguntas excluídas ficam ocultas no FAQ público e podem ser reativadas.</p>
	<cfif len( prc.mensagem )><div class="alert alert-success" role="status">#encodeForHTML( prc.mensagem )#</div></cfif>
	<cfif NOT arrayLen( prc.perguntas )>
		<div class="alert alert-info">Nenhuma pergunta cadastrada. Use “Nova pergunta” para começar.</div>
	<cfelse>
		<div class="row g-3">
			<cfloop array="#prc.perguntas#" item="pergunta">
				<div class="col-12">
					<article class="card shadow-sm">
						<div class="card-body">
							<div class="d-flex flex-wrap align-items-start justify-content-between gap-2 mb-2">
								<h2 class="h5 text-break mb-0">#encodeForHTML( pergunta.txPergunta )#</h2>
								<span class="badge #pergunta.inAtivo ? 'text-bg-success' : 'text-bg-secondary'#">#pergunta.inAtivo ? 'Publicada' : 'Excluída'#</span>
							</div>
							<p class="text-body-secondary text-break" style="white-space: pre-wrap;">#encodeForHTML( pergunta.txResposta )#</p>
							<div class="d-flex flex-wrap gap-2">
								<a href="/administracao/faq/#pergunta.cdFaq#/editar" class="btn btn-outline-primary btn-sm" aria-label="#encodeForHTMLAttribute( 'Editar: ' & pergunta.txPergunta )#">Editar</a>
								<cfif pergunta.inAtivo>
									<a href="/administracao/faq/#pergunta.cdFaq#/excluir" class="btn btn-outline-danger btn-sm" aria-label="#encodeForHTMLAttribute( 'Excluir: ' & pergunta.txPergunta )#">Excluir</a>
								<cfelse>
									<form method="post" action="/administracao/faq/#pergunta.cdFaq#/reativar">
										<button type="submit" class="btn btn-outline-success btn-sm" aria-label="#encodeForHTMLAttribute( 'Reativar: ' & pergunta.txPergunta )#">Reativar</button>
									</form>
								</cfif>
							</div>
						</div>
					</article>
				</div>
			</cfloop>
		</div>
	</cfif>
</cfoutput>
