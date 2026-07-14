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
                            <th>Nome</th>
                            <th>Cargo</th>
                            <th class="d-none d-sm-table-cell">Cidade</th>
                            <th class="d-none d-md-table-cell">Idade</th>
                            <th class="d-none d-lg-table-cell">Data de Início</th>
                            <th class="d-none d-md-table-cell">Salário</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td class="fw-bold">Tiger Nixon</td>
                            <td>Arquiteto</td>
                            <td class="d-none d-sm-table-cell">Edinburgh</td>
                            <td class="d-none d-md-table-cell">61</td>
                            <td class="d-none d-lg-table-cell">2011-04-25</td>
                            <td class="d-none d-md-table-cell">$320,800</td>
                        </tr>
                        <tr>
                            <td class="fw-bold">Garrett Winters</td>
                            <td>Contador</td>
                            <td class="d-none d-sm-table-cell">Tokyo</td>
                            <td class="d-none d-md-table-cell">63</td>
                            <td class="d-none d-lg-table-cell">2011-07-25</td>
                            <td class="d-none d-md-table-cell">$170,750</td>
                        </tr>
                        <tr>
                            <td class="fw-bold">Ashton Cox</td>
                            <td>Autor Técnico</td>
                            <td class="d-none d-sm-table-cell">San Francisco</td>
                            <td class="d-none d-md-table-cell">66</td>
                            <td class="d-none d-lg-table-cell">2009-01-12</td>
                            <td class="d-none d-md-table-cell">$86,000</td>
                        </tr>
                        <tr>
                            <td class="fw-bold">Cedric Kelly</td>
                            <td>Dev Javascript</td>
                            <td class="d-none d-sm-table-cell">Edinburgh</td>
                            <td class="d-none d-md-table-cell">22</td>
                            <td class="d-none d-lg-table-cell">2012-03-29</td>
                            <td class="d-none d-md-table-cell">$433,060</td>
                        </tr>
                        <tr>
                            <td class="fw-bold">Airi Satou</td>
                            <td>Contadora</td>
                            <td class="d-none d-sm-table-cell">Tokyo</td>
                            <td class="d-none d-md-table-cell">33</td>
                            <td class="d-none d-lg-table-cell">2008-11-28</td>
                            <td class="d-none d-md-table-cell">$162,700</td>
                        </tr>
                    </tbody>
                </table>
            </div>

        </div>
    </div>
</cfoutput>