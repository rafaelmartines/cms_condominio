<cfoutput>
    <div class="card shadow-sm border-0">
        <div class="card-header d-flex justify-content-between align-items-center py-3 bg-body-secondary border-bottom">
            <h5 class="mb-0 fw-semibold"><i class="bi bi-person-rolodex me-2 text-primary"></i>Fornecedores</h5>
        </div>
        <div class="card-body">
            
            <form id="formFiltroFornecedores" class="mb-4">
                <div class="row g-3 align-items-end">
                    <!-- Campo: Nome do Fornecedor -->
                    <div class="col-12 col-md-6">
                        <label for="filtroNome" class="form-label fw-medium">Nome do Fornecedor</label>
                        <input type="text" class="form-control" id="filtroNome" placeholder="Ex: Gerente Predial">
                    </div>
                    
                    <!-- Campo: Categoria (Select) -->
                    <div class="col-12 col-md-4">
                        <label for="filtroCategoria" class="form-label fw-medium">Categoria</label>
                        <select class="form-select" id="filtroCategoria">
                            <option value="" selected>Todas as categorias</option>
                            <cfloop array="#prc.categorias#" index="categoria">
                                <option value="#categoria.cdCategoria#">#categoria.txCategoria#</option>
                            </cfloop>
                        </select>
                    </div>
                    
                    <!-- Botão de Ação -->
                    <div class="col-12 col-md-2">
                        <button type="button" id="btnFiltrar" class="btn btn-primary w-100">
                            <i class="bi bi-search me-2"></i>Filtrar
                        </button>
                    </div>
                </div>
            </form>

            <hr class="my-4 text-secondary opacity-25">

            <!-- Tabela HTML Mobile-First -->
            <!-- As classes d-none d-md-table-cell controlam a visibilidade por tamanho de tela -->
            <div class="table-responsive">
                <table id="minhaTabela" class="table table-striped table-hover align-middle mb-0" style="width:100%">
                    <thead>
                        <tr>
                            <th style="width: 45%;">Fornecedor</th>
                            <th class="d-none d-sm-table-cell" style="width: 45%;">Categorias</th>
                            <th style="width: 10%;">Ações</th>
                        </tr>
                    </thead>
                    <tbody> 
                    </tbody>
                </table>
            </div>

        </div>
    </div>
</cfoutput>

<cfsavecontent variable="prc.scripts">
    <script>
        $(document).ready(function() {
            var table = $('#minhaTabela').DataTable({
                language: {
                    url: 'https://cdn.datatables.net/plug-ins/2.0.8/i18n/pt-BR.json',
                },
                ajax: {
                    url: '/api/fornecedores',
                    // Envia os filtros customizados para o servidor na requisição AJAX
                    data: function(d) {
                        d.filtroNome = $('#filtroNome').val();
                        d.filtroCategoria = $('#filtroCategoria').val();
                    }
                },
                searching: false, // REMOVE o campo de pesquisa padrão do DataTables
                columns: [
                    { data: 'nmFornecedor' },
                    { data: 'categorias' },
                    { data: 'html', orderable: false, searchable: false }
                ],
                columnDefs: [
                    { targets: [1], className: 'd-none d-sm-table-cell' } 
                ],
                autoWidth: false, 
                responsive: false, 
                processing: true,
                serverSide: true,
            });

            // Recarrega a tabela processando os novos filtros quando o botão é clicado
            $('#btnFiltrar').on('click', function() {
                table.draw();
            });

            $('#formFiltroFornecedores').on('submit', function(event) {
                event.preventDefault(); // Previne o reload/envio real do formulário
                table.draw();           // Executa a busca no DataTables
            });
        });
    </script>
</cfsavecontent>
