<cfoutput>
	<div class="card shadow-sm border-0 categorias-gestao">
		<div class="card-header py-3 bg-body-secondary d-flex flex-wrap align-items-center justify-content-between gap-3">
			<h1 class="h5 mb-0"><i class="bi bi-tags me-2 text-primary" aria-hidden="true"></i>Categorias de fornecedores</h1>
			<a href="/categorias/adicionar" class="btn btn-primary"><i class="bi bi-plus-lg me-2" aria-hidden="true"></i>Nova categoria</a>
		</div>
		<div class="card-body">
			<div id="reativacaoCategoriaMensagem" class="alert d-none" role="status" tabindex="-1"></div>
			<cfif len( prc.mensagem )>
				<div class="alert alert-success" role="status">#encodeForHTML( prc.mensagem )#</div>
			</cfif>
			<p class="text-body-secondary mb-4">Gerencie as categorias disponíveis nos formulários e filtros. Categorias inativas podem ser reativadas mantendo seus vínculos.</p>
			<cfif arrayIsEmpty( prc.categorias )>
				<div class="alert alert-info mb-0" role="status">Nenhuma categoria cadastrada.</div>
			<cfelse>
				<div class="row g-3 mb-4 align-items-end">
					<div class="col-12 col-md-6">
						<label for="buscaCategoria" class="form-label">Buscar categoria</label>
						<input id="buscaCategoria" type="search" class="form-control" placeholder="Digite o nome da categoria" aria-controls="tabelaCategorias">
					</div>
					<div class="col-6 col-md-3">
						<label for="filtroStatusCategoria" class="form-label">Situação</label>
						<select id="filtroStatusCategoria" class="form-select" aria-controls="tabelaCategorias">
							<option value="">Todas</option>
							<option value="Ativa">Ativas</option>
							<option value="Inativa">Inativas</option>
						</select>
					</div>
					<div class="col-6 col-md-3">
						<label for="limiteCategorias" class="form-label">Por página</label>
						<select id="limiteCategorias" class="form-select" aria-controls="tabelaCategorias">
							<option value="10">10 categorias</option><option value="25">25 categorias</option><option value="50">50 categorias</option>
						</select>
					</div>
				</div>
				<div>
					<table id="tabelaCategorias" class="table table-hover align-middle w-100 mb-0">
						<thead><tr><th scope="col">Categoria</th><th scope="col">Situação</th><th scope="col">Ações</th></tr></thead>
						<tbody>
							<cfloop array="#prc.categorias#" index="categoria">
								<tr>
									<td style="overflow-wrap: anywhere;">#encodeForHTML( categoria.txCategoria )#</td>
									<td data-search="#categoria.inAtivo ? 'Ativa' : 'Inativa'#">
										<span class="badge #categoria.inAtivo ? 'text-bg-success' : 'text-bg-secondary'#">#categoria.inAtivo ? 'Ativa' : 'Inativa'#</span>
									</td>
									<td>
										<div class="d-flex justify-content-end gap-2">
											<a href="/categorias/#categoria.cdCategoria#/editar" class="btn btn-sm btn-outline-primary" aria-label="Editar #encodeForHTMLAttribute( categoria.txCategoria )#" title="Editar"><i class="bi bi-pencil-square" aria-hidden="true"></i></a>
											<cfif categoria.inAtivo>
												<a href="/categorias/#categoria.cdCategoria#/inativar" class="btn btn-sm btn-outline-danger" aria-label="Inativar #encodeForHTMLAttribute( categoria.txCategoria )#" title="Inativar"><i class="bi bi-slash-circle" aria-hidden="true"></i></a>
											<cfelse>
												<button type="button" class="btn btn-sm btn-outline-success" data-reativar-categoria="/categorias/#categoria.cdCategoria#/reativar" aria-label="Reativar #encodeForHTMLAttribute( categoria.txCategoria )#" title="Reativar"><i class="bi bi-arrow-counterclockwise" aria-hidden="true"></i></button>
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
				layout: { topStart: null, topEnd: null, bottomStart: 'info', bottomEnd: 'paging' },
				columnDefs: [
					{ targets: 1, width: '7rem' },
					{ targets: 2, orderable: false, searchable: false, width: '7rem', className: 'text-end text-nowrap' }
				],
				autoWidth: false,
				initComplete: function () {
					$('#tabelaCategorias').wrap('<div class="table-responsive border rounded"></div>');
				}
			});
			$('#buscaCategoria').on('input', function () { tabela.search(this.value).draw(); });
			$('#limiteCategorias').on('change', function () { tabela.page.len(Number(this.value)).draw(); });
			$('#filtroStatusCategoria').on('change', function () {
				tabela.column(1).search(this.value, { exact: true }).draw();
			});
			$('#tabelaCategorias').on('click', '[data-reativar-categoria]', async function () {
				const botao = this;
				const mensagem = document.getElementById('reativacaoCategoriaMensagem');
				botao.disabled = true;
				mensagem.classList.add('d-none');
				try {
					const resposta = await fetch(botao.dataset.reativarCategoria, {
						method: 'PUT', headers: { Accept: 'application/json' }
					});
					const categoria = await resposta.json();
					if (!resposta.ok) throw new Error(categoria.erro || 'Não foi possível reativar a categoria.');
					const linha = botao.closest('tr');
					const situacao = linha.cells[1];
					situacao.dataset.search = 'Ativa';
					situacao.querySelector('.badge').className = 'badge text-bg-success';
					situacao.querySelector('.badge').textContent = 'Ativa';
					const inativar = document.createElement('a');
					inativar.href = `/categorias/${categoria.cdCategoria}/inativar`;
					inativar.className = 'btn btn-sm btn-outline-danger';
					inativar.title = 'Inativar';
					inativar.setAttribute('aria-label', `Inativar ${categoria.txCategoria}`);
					inativar.innerHTML = '<i class="bi bi-slash-circle" aria-hidden="true"></i>';
					botao.replaceWith(inativar);
					tabela.row(linha).invalidate('dom').draw(false);
					mensagem.className = 'alert alert-success';
					mensagem.textContent = 'Categoria reativada com sucesso.';
				} catch (erro) {
					botao.disabled = false;
					mensagem.className = 'alert alert-danger';
					mensagem.textContent = erro.message;
				}
				mensagem.focus({ preventScroll: true });
			});
		});
	</script>
</cfsavecontent>

<cfsavecontent variable="prc.styles">
	<style>
		.categorias-gestao th,
		.categorias-gestao td { padding: 1rem; }
		.categorias-gestao thead { background-color: var(--bs-tertiary-bg); }
		.categorias-gestao .dt-info { color: var(--bs-secondary-color); font-size: .875rem; }
		.categorias-gestao .dt-layout-row:last-child { margin-top: 1rem; row-gap: 1rem; }
		.categorias-gestao .pagination { margin-bottom: 0; flex-wrap: wrap; gap: .25rem; }
		@media (max-width: 575.98px) {
			.categorias-gestao th,
			.categorias-gestao td { padding: .75rem; }
			.categorias-gestao .dt-layout-row:last-child > div { text-align: center; }
			.categorias-gestao .pagination { justify-content: center; }
		}
	</style>
</cfsavecontent>
