<cfoutput>
<h1 class="h3">Aprovação de fornecedores</h1>
<p class="text-body-secondary">Confira os dados antes de publicar o fornecedor na lista.</p>
<cfif len( prc.mensagem )><div class="alert alert-success" role="status">#encodeForHTML( prc.mensagem )#</div></cfif>
<cfif NOT arrayLen( prc.fornecedores )>
	<div class="alert alert-info" role="status">Nenhum fornecedor aguardando aprovação.</div>
</cfif>
<div class="row g-3">
	<cfloop array="#prc.fornecedores#" index="fornecedor">
		<div class="col-12 col-lg-6">
			<div class="card h-100"><div class="card-body">
				<span class="badge text-bg-warning mb-2">Aguardando</span>
				<h2 class="h5 text-break">#encodeForHTML( fornecedor.nm_fornecedor )#</h2>
				<p class="small text-body-secondary mb-2">Prévia do fornecedor</p>
				<dl class="text-break">
					<dt>Empresa</dt><dd>#encodeForHTML( fornecedor.nm_empresa ?: "" )#</dd>
					<dt>Categorias</dt><dd>#encodeForHTML( fornecedor.categorias )#</dd>
					<dt>WhatsApp</dt><dd>#encodeForHTML( fornecedor.nr_telefone ?: "" )#</dd>
					<dt>Instagram</dt><dd>#encodeForHTML( fornecedor.tx_instagram ?: "" )#</dd>
				</dl>
				<div class="d-flex flex-wrap gap-2">
				<form method="post" action="/fornecedores/#fornecedor.cd_fornecedor#/aprovar">
					<input type="hidden" name="csrfToken" value="#encodeForHTMLAttribute( prc.csrfToken )#">
					<button class="btn btn-success" type="submit"><i class="bi bi-check-circle me-2" aria-hidden="true"></i>Aprovar</button>
				</form>
				<form method="post" action="/fornecedores/#fornecedor.cd_fornecedor#/excluir">
					<input type="hidden" name="csrfToken" value="#encodeForHTMLAttribute( prc.csrfToken )#">
					<button class="btn btn-outline-danger" type="submit" aria-label="Excluir #encodeForHTMLAttribute( fornecedor.nm_fornecedor )#"><i class="bi bi-trash me-2" aria-hidden="true"></i>Excluir</button>
				</form>
				</div>
			</div></div>
		</div>
	</cfloop>
</div>
</cfoutput>
