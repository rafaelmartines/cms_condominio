<cfoutput>
    <!-- Modal 1: Aguardando Envio (Loading) -->
    <div class="modal fade" id="modalAguarde" data-bs-backdrop="static" data-bs-keyboard="false" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-sm">
            <div class="modal-content text-center p-4 border-0 shadow">
                <div class="modal-body p-0">
                    <div class="spinner-border text-primary mb-3" style="width: 3rem; height: 3rem;" role="status">
                        <span class="visually-hidden">Carregando...</span>
                    </div>
                    <h6 class="fw-bold mb-1">Enviando avaliação...</h6>
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
                    <div class="text-success display-4 mb-2">
                        <i class="bi bi-check-circle-fill"></i>
                    </div>
                    <h5 class="fw-bold mb-2">Sucesso!</h5>
                    <p class="text-muted small mb-3">Sua avaliação foi enviada com sucesso.</p>
                    <button type="button" class="btn btn-primary w-100" data-bs-dismiss="modal">OK</button>
                </div>
            </div>
        </div>
    </div>
    <div class="row justify-content-center">
            <div class="col-12 col-lg-9">
                
                <!-- Card de Perfil e Ações do Fornecedor -->
                <div class="card shadow-sm border-0 mb-4">
                    <div class="card-body p-4">
                        <div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-3">
                            <div>
                                <cfset tags = listToArray( prc.fornecedor.categorias, "," )>
                                <cfloop array="#tags#" index="tag">
                                    <span class="badge bg-primary-subtle text-primary mb-2">#tag#</span>
                                </cfloop>
                                <h3 class="fw-bold mb-1">#prc.fornecedor.nmFornecedor#</h3>
                            </div>
                            
                            <!-- Classificação por Estrelas (Média Geral) -->
                            <!--- <div class="text-md-end">
                                <div class="text-warning fs-4">
                                    <i class="bi bi-star-fill"></i>
                                    <i class="bi bi-star-fill"></i>
                                    <i class="bi bi-star-fill"></i>
                                    <i class="bi bi-star-fill"></i>
                                    <i class="bi bi-star-half"></i>
                                </div>
                                <span class="fw-bold fs-5">4.8</span>
                                <span class="text-muted small">(42 avaliações)</span>
                            </div> --->
                        </div>

                        <hr class="my-3 text-secondary opacity-25">

                        <!-- Botões de Ação Rápida (Ligar, Whats, Insta, Compartilhar) -->
                        <div class="row g-2">
                            <!-- WhatsApp -->
                            <div class="col-6 col-sm-3">
                                <a href="https://wa.me/#prc.fornecedor.nrTelefone#" target="_blank" class="btn btn-success w-100 d-flex align-items-center justify-content-center gap-2">
                                    <i class="bi bi-whatsapp"></i> WhatsApp
                                </a>
                            </div>

                            <!-- Ligar -->
                            <div class="col-6 col-sm-3">
                                <a href="tel:+#prc.fornecedor.nrTelefone#" class="btn btn-primary w-100 d-flex align-items-center justify-content-center gap-2">
                                    <i class="bi bi-telephone-fill"></i> Ligar
                                </a>
                            </div>

                            <!-- Instagram -->
                            <div class="col-6 col-sm-3">
                                <a href="https://instagram.com/#prc.fornecedor.txInstagram#" target="_blank" class="btn btn-outline-danger w-100 d-flex align-items-center justify-content-center gap-2">
                                    <i class="bi bi-instagram"></i> Instagram
                                </a>
                            </div>

                            <!-- Compartilhar -->
                            <div class="col-6 col-sm-3">
                                <button type="button" class="btn btn-outline-secondary w-100 d-flex align-items-center justify-content-center gap-2" id="btnCompartilhar">
                                    <i class="bi bi-share-fill"></i> Compartilhar
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Card de Novo Comentário e Classificação -->
                <div class="card shadow-sm border-0 mb-4">
                    <div class="card-header bg-body-secondary py-3 border-bottom">
                        <h5 class="mb-0 fw-semibold"><i class="bi bi-chat-left-heart me-2 text-primary"></i>Deixe sua Avaliação</h5>
                    </div>
                    <div class="card-body p-4">
                        <form id="formComentario" class="needs-validation" novalidate>
                            
                            <!-- Seletor de 5 Estrelas -->
                            <div class="mb-3">
                                <label class="form-label d-block fw-medium">Sua Classificação</label>
                                <div class="star-rating-input">
                                    <input type="radio" id="star5" name="rating" value="5" required />
                                    <label for="star5" title="5 estrelas"><i class="bi bi-star-fill"></i></label>
                                    
                                    <input type="radio" id="star4" name="rating" value="4" />
                                    <label for="star4" title="4 estrelas"><i class="bi bi-star-fill"></i></label>
                                    
                                    <input type="radio" id="star3" name="rating" value="3" />
                                    <label for="star3" title="3 estrelas"><i class="bi bi-star-fill"></i></label>
                                    
                                    <input type="radio" id="star2" name="rating" value="2" />
                                    <label for="star2" title="2 estrelas"><i class="bi bi-star-fill"></i></label>
                                    
                                    <input type="radio" id="star1" name="rating" value="1" />
                                    <label for="star1" title="1 estrela"><i class="bi bi-star-fill"></i></label>
                                </div>
                                <div class="invalid-feedback">Por favor, selecione uma classificação em estrelas.</div>
                            </div>

                            <!-- Nome e Comentário -->
                            <div class="mb-3">
                                <label for="nomeAvaliador" class="form-label fw-medium">Seu Nome</label>
                                <input type="text" class="form-control" id="nomeAvaliador" placeholder="Ex: Carlos Andrade" required>
                                <div class="invalid-feedback">Informe seu nome.</div>
                            </div>

                            <div class="mb-3">
                                <label for="textoComentario" class="form-label fw-medium">Comentário</label>
                                <textarea class="form-control" id="textoComentario" rows="3" placeholder="Escreva sua experiência com este fornecedor..." required></textarea>
                                <div class="invalid-feedback">Por favor, digite seu comentário.</div>
                            </div>

                            <div class="d-flex justify-content-end">
                                <button type="submit" class="btn btn-primary px-4" id="btnEnviarComentario">
                                    <i class="bi bi-send me-2"></i>Enviar Avaliação
                                </button>
                            </div>
                        </form>
                    </div>
                </div>

                <!-- Seção de Lista de Comentários -->
                <div class="card shadow-sm border-0">
                    <div class="card-header bg-body-secondary py-3 border-bottom d-flex justify-content-between align-items-center">
                        <h5 class="mb-0 fw-semibold"><i class="bi bi-chat-square-text me-2 text-primary"></i>Comentários Recentes (Em breve)</h5>
                        <!--- <span class="badge bg-secondary-subtle text-body border border-secondary-subtle">3 exibidos</span> --->
                    </div>
                    <!--- <div class="card-body p-4">
                        
                        <!-- Lista de Comentários -->
                        <div class="d-flex flex-column gap-4">
                            
                            <!-- Comentário 1 -->
                            <div class="d-flex gap-3 align-items-start border-bottom pb-3">
                                <div class="avatar-circle bg-primary-subtle text-primary">
                                    MS
                                </div>
                                <div class="w-100">
                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                        <h6 class="mb-0 fw-bold">Mariana Silva</h6>
                                        <small class="text-muted">Há 2 dias</small>
                                    </div>
                                    <div class="text-warning small mb-2">
                                        <i class="bi bi-star-fill"></i>
                                        <i class="bi bi-star-fill"></i>
                                        <i class="bi bi-star-fill"></i>
                                        <i class="bi bi-star-fill"></i>
                                        <i class="bi bi-star-fill"></i>
                                    </div>
                                    <p class="mb-0 text-body-secondary">Entrega rápida e excelente atendimento. Os produtos chegaram em perfeito estado e antes do prazo combinado.</p>
                                </div>
                            </div>

                            <!-- Comentário 2 -->
                            <div class="d-flex gap-3 align-items-start border-bottom pb-3">
                                <div class="avatar-circle bg-success-subtle text-success">
                                    R2
                                </div>
                                <div class="w-100">
                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                        <h6 class="mb-0 fw-bold">Roberto Souza</h6>
                                        <small class="text-muted">Há 1 semana</small>
                                    </div>
                                    <div class="text-warning small mb-2">
                                        <i class="bi bi-star-fill"></i>
                                        <i class="bi bi-star-fill"></i>
                                        <i class="bi bi-star-fill"></i>
                                        <i class="bi bi-star-fill"></i>
                                        <i class="bi bi-star"></i>
                                    </div>
                                    <p class="mb-0 text-body-secondary">Ótima variedade de produtos. Tivemos um pequeno atraso na emissão da nota fiscal, mas resolveram rapidamente via WhatsApp.</p>
                                </div>
                            </div>

                            <!-- Comentário 3 -->
                            <div class="d-flex gap-3 align-items-start">
                                <div class="avatar-circle bg-warning-subtle text-warning">
                                    FP
                                </div>
                                <div class="w-100">
                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                        <h6 class="mb-0 fw-bold">Fernanda Pereira</h6>
                                        <small class="text-muted">Há 3 semanas</small>
                                    </div>
                                    <div class="text-warning small mb-2">
                                        <i class="bi bi-star-fill"></i>
                                        <i class="bi bi-star-fill"></i>
                                        <i class="bi bi-star-fill"></i>
                                        <i class="bi bi-star-fill"></i>
                                        <i class="bi bi-star-fill"></i>
                                    </div>
                                    <p class="mb-0 text-body-secondary">Parceiro de confiança há mais de 2 anos. Sempre cobrem os preços da concorrência e oferecem ótimas condições de pagamento.</p>
                                </div>
                            </div>

                        </div>

                    </div> --->
                </div>

            </div>
        </div>
</cfoutput>

<cfsavecontent variable="prc.styles">
    <style>
        .star-rating-input {
            display: flex;
            flex-direction: row-reverse;
            justify-content: flex-end;
        }
        .star-rating-input input[type="radio"] {
            display: none;
        }
        .star-rating-input label {
            font-size: 1.5rem;
            color: #ddd;
            cursor: pointer;
            transition: color 0.2s;
        }
        .star-rating-input input[type="radio"]:checked ~ label,
        .star-rating-input label:hover,
        .star-rating-input label:hover ~ label {
            color: #ffc107; /* Cor das estrelas selecionadas */
        }

        .avatar-circle {
            width: 45px;
            height: 45px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
        }

        @media (max-width: 576px) {
            .card-body {
                padding: 1.25rem;
            }
        }
    </style>
</cfsavecontent>

<cfsavecontent variable="prc.scripts">
    <script>
        (() => {
            'use strict';
            <cfoutput>
                const cdFornecedor = #prc.fornecedor.cdFornecedor#;
            </cfoutput>
            const form = document.getElementById('formComentario');
            const btnEnviar = document.getElementById('btnEnviarComentario');
            
            // Instâncias dos Modais do Bootstrap
            const modalAguarde = new bootstrap.Modal(document.getElementById('modalAguarde'));
            const modalSucesso = new bootstrap.Modal(document.getElementById('modalSucesso'));

            form.addEventListener('submit', async (event) => {
            event.preventDefault();

            // 1. Validação nativa do formulário
            if (!form.checkValidity()) {
                event.stopPropagation();
                form.classList.add('was-validated');
                return;
            }

            // 2. Coleta os dados do formulário
            const formData = {
                nrNota: form.querySelector('input[name="rating"]:checked')?.value,
                nmNome: document.getElementById('nomeAvaliador').value,
                txConteudo: document.getElementById('textoComentario').value,
                cdFornecedor: cdFornecedor // Altere para o ID dinâmico do fornecedor se necessário
            };

            // 3. Bloqueia o botão e ativa o estado de carregamento
            btnEnviar.disabled = true;
            const textoOriginalBotao = btnEnviar.innerHTML;
            btnEnviar.innerHTML = `<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>Enviando...`;

            // 4. Exibe o modal de "Aguarde"
            modalAguarde.show();

            try {
                // 5. Envio real via FETCH para a API
                const response = await fetch('/api/fornecedores/' + cdFornecedor + '/testemunho', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify(formData)
                });

                // Verifica se a API retornou erro HTTP (4xx ou 5xx)
                if (!response.ok) {
                    throw new Error(`Erro na requisição: ${response.status}`);
                }

                // Opcional: Ler a resposta JSON da API caso precise tratar algo
                const data = await response.json();

                // 6. Sucesso: Limpa o formulário e exibe o modal de confirmação
                form.reset();
                form.classList.remove('was-validated');
                
                // Aguarda o modal de carregamento fechar completamente antes de abrir o de sucesso
                modalAguarde.hide();
                modalSucesso.show();

            } catch (error) {
                console.error('Erro ao enviar avaliação:', error);
                
                modalAguarde.hide();
                alert('Não foi possível enviar sua avaliação no momento. Tente novamente mais tarde.');

            } finally {
                // 7. Reabilita o botão independente do resultado
                btnEnviar.disabled = false;
                btnEnviar.innerHTML = textoOriginalBotao;
            }
        });
        })();
    </script>
</cfsavecontent>
