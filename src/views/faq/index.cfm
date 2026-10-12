<cfoutput>
	<div class="mx-auto" style="max-width: 54rem;">
		<h1 class="h3 mb-2">Perguntas frequentes</h1>
		<p class="text-body-secondary">Encontre respostas para suas dúvidas. Clique em uma pergunta para ver a resposta.</p>
		<form method="get" action="/faq" role="search" class="mb-4">
			<label for="buscaFaq" class="form-label">Buscar nas perguntas</label>
			<div class="d-flex flex-wrap gap-2">
				<input type="search" name="busca" id="buscaFaq" class="form-control flex-grow-1" style="flex-basis: 15rem;" value="#encodeForHTMLAttribute( prc.busca )#" maxlength="300" placeholder="Digite sua dúvida">
				<button type="submit" class="btn btn-primary"><i class="bi bi-search me-2" aria-hidden="true"></i>Buscar</button>
				<cfif len( prc.busca )><a href="/faq" class="btn btn-outline-secondary">Limpar busca</a></cfif>
			</div>
		</form>
		<p role="status" class="text-body-secondary small">#arrayLen( prc.perguntas )# pergunta(s) encontrada(s).</p>
		<cfif NOT arrayLen( prc.perguntas )>
			<div class="alert alert-info">
				<cfif len( prc.busca )>Nenhuma pergunta encontrada. Tente buscar por outras palavras.<cfelse>Ainda não há perguntas frequentes publicadas.</cfif>
			</div>
		<cfelse>
			<div class="accordion" id="faqAccordion">
				<cfloop array="#prc.perguntas#" item="pergunta">
					<div class="accordion-item">
						<h2 class="accordion-header" id="faqTitulo#pergunta.cdFaq#">
							<button class="accordion-button collapsed text-break" type="button" data-bs-toggle="collapse" data-bs-target="##faqResposta#pergunta.cdFaq#" aria-expanded="false" aria-controls="faqResposta#pergunta.cdFaq#">#encodeForHTML( pergunta.txPergunta )#</button>
						</h2>
						<div id="faqResposta#pergunta.cdFaq#" class="accordion-collapse collapse" aria-labelledby="faqTitulo#pergunta.cdFaq#" data-bs-parent="##faqAccordion">
							<div class="accordion-body text-break" style="white-space: pre-wrap;">#encodeForHTML( pergunta.txResposta )#</div>
						</div>
					</div>
				</cfloop>
			</div>
			<noscript><style>.accordion-collapse.collapse { display: block; }</style><p class="small mt-3">JavaScript desativado: todas as respostas estão abertas.</p></noscript>
		</cfif>
	</div>
</cfoutput>
