<cfoutput>
<div class="row justify-content-center fornecedor-cadastro">
	<div class="col-12 col-md-10 col-lg-8 col-xl-7">
		<h1 class="h3">Cadastrar fornecedor</h1>
		<p class="text-body-secondary mb-4">Cadastre fornecedores já aprovados. O fornecedor será publicado na lista ao salvar.</p>
		<cfif len( prc.mensagem )><div class="alert alert-success" role="status">#encodeForHTML( prc.mensagem )#</div></cfif>
		<cfif len( prc.erro )><div class="alert alert-danger" role="alert">#encodeForHTML( prc.erro )#</div></cfif>
		<form method="post" action="/fornecedores/adicionar" class="card card-body p-3 p-sm-4 shadow-sm">
			<p class="small text-body-secondary mb-3">Campos com * são obrigatórios.</p>
			<div class="mb-4">
				<label for="nmFornecedor" class="form-label fw-semibold">Nome do fornecedor *</label>
				<input id="nmFornecedor" name="nmFornecedor" type="text" class="form-control" required maxlength="100" autocomplete="name" placeholder="Nome do profissional ou negócio" value="#encodeForHTMLAttribute( prc.dados.nmFornecedor )#">
			</div>
			<div class="mb-4">
				<label for="nrTelefone" class="form-label fw-semibold">WhatsApp *</label>
				<input id="nrTelefone" name="nrTelefone" type="tel" inputmode="tel" autocomplete="tel" class="form-control" required maxlength="25" aria-describedby="telefoneAjuda" placeholder="55 11 99999-9999" value="#encodeForHTMLAttribute( prc.dados.nrTelefone )#">
				<div id="telefoneAjuda" class="form-text">Inclua o código do país e o DDD. Exemplo: 55 11 99999-9999.</div>
			</div>
			<fieldset class="mb-4" aria-describedby="categoriasAjuda">
				<legend class="fs-6 fw-semibold mb-1">Serviços / categorias *</legend>
				<p id="categoriasAjuda" class="small text-body-secondary mb-3">Toque para selecionar uma ou mais opções.</p>
				<div class="row g-2">
					<cfloop array="#prc.categorias#" index="categoria">
						<div class="col-12 col-sm-6">
							<label class="fornecedor-categoria d-flex align-items-center gap-3 border rounded p-3 h-100" for="categoria-#categoria.cdCategoria#">
								<input class="form-check-input flex-shrink-0 m-0" type="checkbox" name="categorias" id="categoria-#categoria.cdCategoria#" value="#categoria.cdCategoria#" <cfif arrayFind( prc.dados.categorias, categoria.cdCategoria )>checked</cfif>>
								<span class="text-break">#encodeForHTML( categoria.txCategoria )#</span>
							</label>
						</div>
					</cfloop>
				</div>
				<cfif NOT arrayLen( prc.categorias )><p class="text-body-secondary">Nenhuma categoria ativa. Solicite o cadastro de uma categoria antes de continuar.</p></cfif>
			</fieldset>
			<details class="border rounded mb-4" <cfif len( prc.dados.nmEmpresa ) OR len( prc.dados.txInstagram )>open</cfif>>
				<summary class="p-3 fw-semibold">Mais informações <span class="fw-normal text-body-secondary">(opcional)</span></summary>
				<div class="px-3 pb-3 pt-2">
					<div class="mb-3">
						<label for="nmEmpresa" class="form-label">Empresa</label>
						<input id="nmEmpresa" name="nmEmpresa" type="text" autocomplete="organization" class="form-control" maxlength="150" value="#encodeForHTMLAttribute( prc.dados.nmEmpresa )#">
					</div>
					<div>
						<label for="txInstagram" class="form-label">Instagram</label>
						<input id="txInstagram" name="txInstagram" type="text" autocapitalize="none" spellcheck="false" class="form-control" maxlength="31" aria-describedby="instagramAjuda" placeholder="@usuario" value="#encodeForHTMLAttribute( prc.dados.txInstagram )#">
						<div id="instagramAjuda" class="form-text">Somente o nome de usuário, sem o link.</div>
					</div>
				</div>
			</details>
			<div class="d-grid gap-2 d-sm-flex">
				<button class="btn btn-primary flex-sm-grow-1" type="submit" <cfif NOT arrayLen( prc.categorias )>disabled</cfif>>Cadastrar fornecedor</button>
				<a class="btn btn-outline-secondary" href="/">Voltar à lista</a>
			</div>
		</form>
	</div>
</div>
</cfoutput>

<cfsavecontent variable="prc.styles">
	<style>
		.fornecedor-cadastro .form-control,
		.fornecedor-cadastro .btn {
			min-height: 48px;
			font-size: 1rem;
		}
		.fornecedor-cadastro .btn {
			display: inline-flex;
			align-items: center;
			justify-content: center;
			white-space: normal;
		}
		.fornecedor-cadastro summary,
		.fornecedor-categoria {
			cursor: pointer;
			min-height: 48px;
		}
		.fornecedor-categoria:focus-within {
			outline: 2px solid var(--bs-primary);
			outline-offset: 2px;
		}
		.fornecedor-categoria:has(input:checked) {
			background-color: var(--bs-primary-bg-subtle);
			border-color: var(--bs-primary) !important;
		}
	</style>
</cfsavecontent>
