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