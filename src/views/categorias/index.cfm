<cfoutput>
	<div class="card shadow-sm border-0">
		<div class="card-header py-3 bg-body-secondary d-flex flex-wrap align-items-center justify-content-between gap-3">
			<h1 class="h5 mb-0"><i class="bi bi-tags me-2 text-primary" aria-hidden="true"></i>Categorias de fornecedores</h1>
			<a href="/categorias/adicionar" class="btn btn-primary"><i class="bi bi-plus-lg me-2" aria-hidden="true"></i>Nova categoria</a>
		</div>
		<div class="card-body">
			<cfif len( prc.mensagem )>
				<div class="alert alert-success" role="status">#encodeForHTML( prc.mensagem )#</div>
			</cfif>
			<p class="text-body-secondary">Crie categorias, edite os nomes ou inative categorias que não devem mais aparecer nas opções dos formulários e filtros.</p>
			<cfif arrayIsEmpty( prc.categorias )>
				<div class="alert alert-info mb-0" role="status">Nenhuma categoria cadastrada.</div>
			<cfelse>
				<div class="mb-3" style="max-width: 18rem;">
					<label for="filtroStatusCategoria" class="form-label">Situação</label>
					<select id="filtroStatusCategoria" class="form-select">
						<option value="">Todas</option>
						<option value="Ativa">Ativas</option>
						<option value="Inativa">Inativas</option>
					</select>
				</div>
				<div class="table-responsive">
					<table id="tabelaCategorias" class="table table-striped table-hover align-middle w-100">
						<thead><tr><th scope="col">Categoria</th><th scope="col">Situação</th><th scope="col">Ações</th></tr></thead>
						<tbody>
							<cfloop array="#prc.categorias#" index="categoria">
								<tr>
									<td style="overflow-wrap: anywhere;">#encodeForHTML( categoria.txCategoria )#</td>
									<td data-search="#categoria.inAtivo ? 'Ativa' : 'Inativa'#">
										<span class="badge #categoria.inAtivo ? 'text-bg-success' : 'text-bg-secondary'#">#categoria.inAtivo ? 'Ativa' : 'Inativa'#</span>
									</td>
									<td>
										<div class="d-flex flex-wrap gap-2">
											<a href="/categorias/#categoria.cdCategoria#/editar" class="btn btn-sm btn-outline-primary" aria-label="Editar #encodeForHTMLAttribute( categoria.txCategoria )#" title="Editar"><i class="bi bi-pencil-square" aria-hidden="true"></i></a>
											<cfif categoria.inAtivo>
												<a href="/categorias/#categoria.cdCategoria#/inativar" class="btn btn-sm btn-outline-danger" aria-label="Inativar #encodeForHTMLAttribute( categoria.txCategoria )#" title="Inativar"><i class="bi bi-slash-circle" aria-hidden="true"></i></a>
											</cfif>
										</div>
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</div>
			</cfif>
		</div>
	</div>
</cfoutput>

<cfsavecontent variable="prc.scripts">
	<script>
		$(function () {
			if (!document.getElementById('tabelaCategorias')) return;
			const tabela = $('#tabelaCategorias').DataTable({
				language: { url: '/includes/vendor/datatables/2.0.8/i18n/pt-BR.json' },
				order: [[0, 'asc']],
				columnDefs: [{ targets: 2, orderable: false, searchable: false }],
				autoWidth: false
			});
			$('#filtroStatusCategoria').on('change', function () {
				tabela.column(1).search(this.value, { exact: true }).draw();
			});
		});
	</script>
</cfsavecontent>
