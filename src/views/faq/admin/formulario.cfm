<cfoutput>
	<div class="mx-auto" style="max-width: 48rem;">
		<a href="/administracao/faq" class="btn btn-link px-0 mb-3">Voltar às perguntas</a>
		<div class="card shadow-sm">
			<div class="card-body">
				<h1 class="h4 mb-3">#encodeForHTML( prc.titulo )#</h1>
				<cfif NOT prc.pergunta.inAtivo><p class="alert alert-info">Esta pergunta está excluída. Salvar alterações mantém essa situação; use “Reativar” na listagem para publicá-la novamente.</p></cfif>
				<cfif len( prc.erroFormulario )><div class="alert alert-danger" role="alert" id="erroFormulario">#encodeForHTML( prc.erroFormulario )#</div></cfif>
				<form method="post" action="#prc.novaPergunta ? '/administracao/faq/adicionar' : '/administracao/faq/' & prc.pergunta.cdFaq & '/editar'#">
					<div class="mb-3">
						<label for="txPergunta" class="form-label">Pergunta</label>
						<input type="text" name="txPergunta" id="txPergunta" class="form-control" value="#encodeForHTMLAttribute( prc.pergunta.txPergunta )#" maxlength="300" required aria-describedby="ajudaPergunta">
						<div class="form-text" id="ajudaPergunta">De 1 a 300 caracteres.</div>
					</div>
					<div class="mb-4">
						<label for="txResposta" class="form-label">Resposta</label>
						<textarea name="txResposta" id="txResposta" class="form-control" rows="8" maxlength="10000" required aria-describedby="ajudaResposta">#encodeForHTML( prc.pergunta.txResposta )#</textarea>
						<div class="form-text" id="ajudaResposta">De 1 a 10.000 caracteres. Use texto simples; as quebras de linha serão preservadas.</div>
					</div>
					<div class="d-flex flex-wrap gap-2">
						<button type="submit" class="btn btn-primary">#prc.novaPergunta ? 'Criar pergunta' : 'Salvar alterações'#</button>
						<a href="/administracao/faq" class="btn btn-outline-secondary">Cancelar</a>
					</div>
				</form>
			</div>
		</div>
	</div>
</cfoutput>
