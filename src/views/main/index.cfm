<cfoutput>
    <div class="card shadow-sm border-0">
        <div class="card-header d-flex justify-content-between align-items-center py-3 bg-body-secondary border-bottom">
            <h5 class="mb-0 fw-semibold"><i class="bi bi-person-rolodex me-2 text-primary"></i>Fornecedores</h5>
            <span class="badge bg-primary-subtle text-primary border border-primary-subtle">Filtro Ativo</span>
        </div>
        <div class="card-body">
            
            <!-- Tabela HTML Mobile-First -->
            <!-- As classes d-none d-md-table-cell controlam a visibilidade por tamanho de tela -->
            <div class="table-responsive">
                <table id="minhaTabela" class="table table-striped table-hover align-middle mb-0" style="width:100%">
                    <thead>
                        <tr>
                            <th style="width: 45%;">Fornecedor</th>
                            <th class="d-none d-sm-table-cell" style="width: 45%;">Empresa</th>
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
    <script type="text/javascript">
        $(document).ready(function() {
            $('#minhaTabela').DataTable({
                language: {
                    url: 'https://cdn.datatables.net/plug-ins/2.0.8/i18n/pt-BR.json',
                },
                ajax: {
                    url: '/api/fornecedores'
                },
                columns: [
                    { data: 'nmFornecedor' },
                    { data: 'nmEmpresa' },
                    { data: 'html', orderable: false, searchable: false }
                ],
                columnDefs: [
                    { targets: [1], className: 'd-none d-sm-table-cell' } // Oculta a coluna "Empresa" em telas menores que 576px
                ],
                autoWidth: false, // Evita que o DataTables force larguras fixas nas colunas ocultas
                responsive: false, // Desativado para usar o controle de visualização do próprio Bootstrap
                processing: true,
                serverSide: true,
            });
        });
    </script>
</cfsavecontent>
