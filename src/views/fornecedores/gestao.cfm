<cfoutput>
	<a href="/" class="btn btn-link px-0 mb-3"><i class="bi bi-arrow-left me-2" aria-hidden="true"></i>Voltar ao início</a>
	<h1 class="h3 mb-2">Gerenciar fornecedores</h1>
	<p class="text-body-secondary">Consulte os fornecedores aprovados, cadastre um fornecedor já aprovado ou revise as indicações pendentes.</p>
	<div class="d-flex flex-wrap gap-2 mb-4">
		<a href="/fornecedores/adicionar" class="btn btn-primary"><i class="bi bi-person-plus me-2" aria-hidden="true"></i>Cadastrar fornecedor aprovado</a>
		<a href="/fornecedores/aprovacao" class="btn btn-outline-primary"><i class="bi bi-check-circle me-2" aria-hidden="true"></i>Aprovação de fornecedores</a>
		<a href="/fornecedores" class="btn btn-outline-secondary">Ver lista pública</a>
	</div>
</cfoutput>
<cfinclude template="_listagem.cfm">
