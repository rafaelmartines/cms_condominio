<cfoutput>
    <!-- Modal 1: Aguardando Envio -->
        <div class="modal fade" id="modalAguarde" data-bs-backdrop="static" data-bs-keyboard="false" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-sm">
                <div class="modal-content text-center p-4 border-0 shadow">
                    <div class="modal-body p-0">
                        <div class="spinner-border text-primary mb-3" style="width: 3rem; height: 3rem;" role="status">
                            <span class="visually-hidden">Carregando...</span>
                        </div>
                        <h6 class="fw-bold mb-1">Enviando indicação...</h6>
                        <p class="text-muted small mb-0">Por favor, aguarde um momento.</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Modal 2: Sucesso -->
        <div class="modal fade" id="modalSucesso" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-sm">
                <div class="modal-content text-center p-4 border-0 shadow">
                    <div class="modal-body p-0">
                        <div class="text-success display-4 mb-2"><i class="bi bi-check-circle-fill"></i></div>
                        <h5 class="fw-bold mb-2">Sucesso!</h5>
                        <p class="text-muted small mb-3">Indicação enviada com sucesso. Obrigado!</p>
                        <button type="button" class="btn btn-primary w-100" data-bs-dismiss="modal">OK</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="row justify-content-center">
            <div class="col-12 col-lg-8">
                
                <div class="card shadow-sm border-0 mb-4">
                    <div class="card-header bg-body-secondary py-3 border-bottom">
                        <h5 class="mb-0 fw-semibold"><i class="bi bi-person-plus me-2 text-primary"></i>Indicar Novo Fornecedor</h5>
                    </div>
                    <div class="card-body p-4">
                        <form id="formIndicacao" class="needs-validation" novalidate>
                            
                            <!-- Dados do Fornecedor -->
                            <h6 class="text-primary fw-bold mb-3"><i class="bi bi-shop me-2"></i>Dados do Fornecedor</h6>
                            
                            <div class="mb-3">
                                <label for="nomeFornecedor" class="form-label fw-medium">Nome do Fornecedor *</label>
                                <input type="text" class="form-control" id="nomeFornecedor" placeholder="Ex: Gildo Persianas" required>
                                <div class="invalid-feedback">Por favor, informe o nome do fornecedor.</div>
                            </div>

                            <!-- CAMPO NOVO: Categoria (Multi-seleção) -->
                            <div class="mb-3">
                                <label for="categoriasFornecedor" class="form-label fw-medium">Categoria(s) * <small class="text-muted">(pressione Ctrl/Cmd para selecionar mais de uma)</small></label>
                                <select class="form-select" id="categoriasFornecedor" multiple aria-label="Selecione as categorias" required style="height: 120px;">
                                    <cfloop array="#prc.categorias#" index="categoria">
                                        <option value="#categoria.cdCategoria#">#categoria.txCategoria#</option>
                                    </cfloop>
                                </select>
                                <div class="invalid-feedback">Selecione pelo menos uma categoria.</div>
                            </div>

                            <div class="mb-3">
                                <label for="whatsappFornecedor" class="form-label fw-medium">WhatsApp do Fornecedor *</label>
                                <div class="input-group has-validation">
                                    <span class="input-group-text"><i class="bi bi-whatsapp"></i></span>
                                    <input type="text" class="form-control" id="whatsappFornecedor" placeholder="+55 11 99999-9999" pattern="\+55\s[0-9]{2}\s9[0-9]{4}-[0-9]{4}" maxlength="17" required>
                                    <div class="invalid-feedback">Informe um WhatsApp válido no formato +55 11 99999-9999.</div>
                                </div>
                            </div>

                            <div class="mb-4">
                                <label for="instagramFornecedor" class="form-label fw-medium">Instagram do Fornecedor <small class="text-muted">(opcional)</small></label>
                                <div class="input-group">
                                    <span class="input-group-text text-muted">https://www.instagram.com/</span>
                                    <input type="text" class="form-control" id="instagramFornecedor" placeholder="usuario">
                                </div>
                            </div>

                            <hr class="my-4 text-secondary opacity-25">

                            <!-- Dados de Quem Está Indicando -->
                            <h6 class="text-primary fw-bold mb-3"><i class="bi bi-person-badge me-2"></i>Sua Identificação</h6>

                            <div class="row">
                                <div class="col-md-8 mb-3">
                                    <label for="nomeIndicador" class="form-label fw-medium">Seu Nome *</label>
                                    <input type="text" class="form-control" id="nomeIndicador" placeholder="Ex: Maria Silva" required>
                                    <div class="invalid-feedback">Por favor, informe seu nome.</div>
                                </div>

                                <div class="col-md-4 mb-3">
                                    <label for="numeroApartamento" class="form-label fw-medium">Número do Ap. *</label>
                                    <input type="number" class="form-control" id="numeroApartamento" placeholder="Ex: 101" min="0" required>
                                    <div class="invalid-feedback">Informe o número do apartamento.</div>
                                </div>
                            </div>

                            <div class="mb-4">
                                <label for="motivoRecomendacao" class="form-label fw-medium">Motivo da Recomendação *</label>
                                <textarea class="form-control" id="motivoRecomendacao" rows="3" placeholder="Conte brevemente por que você recomenda este profissional..." required></textarea>
                            </div>

                            <div class="d-flex justify-content-end gap-2">
                                <button type="submit" class="btn btn-primary px-4" id="btnEnviarIndicacao">
                                    <i class="bi bi-send me-2"></i>Enviar Indicação
                                </button>
                            </div>

                        </form>
                    </div>
                </div>

            </div>
        </div>
</cfoutput>

<cfsavecontent variable="prc.scripts">
    <script>
    (() => {
            'use strict';

            const inputWhatsapp = document.getElementById('whatsappFornecedor');
            const form = document.getElementById('formIndicacao');
            const btnEnviar = document.getElementById('btnEnviarIndicacao');
            
            const modalAguarde = new bootstrap.Modal(document.getElementById('modalAguarde'));
            const modalSucesso = new bootstrap.Modal(document.getElementById('modalSucesso'));

            // Máscara Automática (+55 11 99999-9999)
            inputWhatsapp.addEventListener('input', (e) => {
                let v = e.target.value.replace(/\D/g, '');
                
                if (v.startsWith('55')) v = v.substring(2);
                if (v.length > 11) v = v.substring(0, 11);

                let formatted = '+55 ';
                if (v.length > 0) formatted += v.substring(0, 2);
                if (v.length > 2) formatted += ' ' + v.substring(2, 7);
                if (v.length > 7) formatted += '-' + v.substring(7, 11);

                e.target.value = v.length === 0 ? '' : formatted;
            });

            // Envio do Formulário
            form.addEventListener('submit', async (event) => {
                event.preventDefault();

                if (!form.checkValidity()) {
                    event.stopPropagation();
                    form.classList.add('was-validated');
                    return;
                }

                // Captura as opções selecionadas no campo multi-select de Categorias
                const categoriasSelect = document.getElementById('categoriasFornecedor');
                const categoriasSelecionadas = Array.from(categoriasSelect.selectedOptions).map(option => option.value);

                // Trata o campo Instagram
                const instaUser = document.getElementById('instagramFornecedor').value.trim().replace(/^@/, '');
                const instagramUrl = instaUser ? `https://www.instagram.com/${instaUser}` : null;

                const formData = {
                    nmFornecedor: document.getElementById('nomeFornecedor').value,
                    categorias: categoriasSelecionadas, // Array com as categorias escolhidas
                    nrWhatsapp: inputWhatsapp.value,
                    txInstagram: instagramUrl,
                    nmIndicador: document.getElementById('nomeIndicador').value,
                    nrApartamento: document.getElementById('numeroApartamento').value,
                    txMotivo: document.getElementById('motivoRecomendacao').value
                };

                btnEnviar.disabled = true;
                const textoOriginalBotao = btnEnviar.innerHTML;
                btnEnviar.innerHTML = `<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>Enviando...`;

                modalAguarde.show();

                try {
                    const response = await fetch('/api/fornecedores/indicacao', {
                        method: 'POST',
                        headers: { 
                            'Content-Type': 'application/json',
                            'Accept': 'application/json' 
                        },
                        body: JSON.stringify(formData)
                    });

                    if (!response.ok) throw new Error(`Erro: ${response.status}`);

                    form.reset();
                    form.classList.remove('was-validated');
                    modalAguarde.hide();
                    modalSucesso.show();

                } catch (error) {
                    console.error('Erro ao enviar indicação:', error);
                    modalAguarde.hide();
                    alert('Não foi possível enviar a indicação no momento. Tente novamente.');
                } finally {
                    btnEnviar.disabled = false;
                    btnEnviar.innerHTML = textoOriginalBotao;
                }
            });
        })();
    </script>
</cfsavecontent>
