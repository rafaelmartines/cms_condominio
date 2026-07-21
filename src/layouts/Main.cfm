<cfoutput>
<!DOCTYPE html>
    <html lang="pt-BR" data-bs-theme="dark">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Vivão - Lista de Fornecedores</title>
        
        <!-- Bootstrap 5 CSS -->
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
        
        <!-- DataTables Bootstrap 5 Styling CSS -->
        <link href="https://cdn.datatables.net/2.0.8/css/dataTables.bootstrap5.min.css" rel="stylesheet">
        
        <!-- Bootstrap Icons -->
        <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">

        <style>
            body {
                display: flex;
                flex-direction: column;
                min-height: 100vh;
            }
            
            main {
                flex: 1;
            }

            /* Estilos para o botão flutuante de tema */
            .theme-switcher {
                position: fixed;
                bottom: 20px;
                right: 20px;
                z-index: 1050;
            }

            /* Ajustes dinâmicos para o DataTables herdar as variáveis de cor do Bootstrap */
            .dt-search input, .dt-length select {
                background-color: var(--bs-body-bg) !important;
                color: var(--bs-body-color) !important;
                border: 1px solid var(--bs-border-color) !important;
            }

            /* Ajuste mobile: diminui um pouco as fontes do DataTables em telas muito pequenas */
            @media (max-width: 576px) {
                .dt-search, .dt-length, .dt-info, .dt-paging {
                    font-size: 0.875rem;
                    margin-bottom: 0.5rem;
                }
                .card-body {
                    padding: 0.75rem;
                }
            }
        </style>
    </head>
</head>
<body>
	<!---Top NavBar --->
	<header>
		<nav class="navbar border-bottom bg-body-vertical">
            <div class="container">
                <a class="navbar-brand fw-bold" href="##"><i class="bi bi-building me-2 text-primary"></i>Vivão</a>
                
                <!-- O botão de hamburguer agora fica visível em qualquer resolução -->
                <button class="navbar-toggler ms-auto" type="button" data-bs-toggle="offcanvas" data-bs-target="##menuLateralDireito" aria-controls="menuLateralDireito">
                    <span class="navbar-toggler-icon"></span>
                </button>
            </div>
        </nav>

        <!-- Menu Lateral Direito (Offcanvas) -->
        <div class="offcanvas offcanvas-end" tabindex="-1" id="menuLateralDireito" aria-labelledby="menuLateralDireitoLabel">
            <div class="offcanvas-header border-bottom">
                <h5 class="offcanvas-title fw-bold" id="menuLateralDireitoLabel"><i class="bi bi-list me-2"></i>Navegação</h5>
                <button type="button" class="btn-close" data-bs-dismiss="offcanvas" aria-label="Close"></button>
            </div>
            <div class="offcanvas-body p-0">
                <!-- Links do Menu -->
                <div class="list-group list-group-flush">
                    <a href="/" class="list-group-item list-group-item-action active py-3"><i class="bi bi-house-door me-3"></i>Início</a>
                    <a href="https://uclass.com.br/bn/vbstar/" target="_blank" class="list-group-item list-group-item-action py-3"><i class="bi bi-box-arrow-up-right"></i> Manual do Proprietário</a>
                </div>
            </div>
        </div>
	</header>

	<!---Container And Views --->
	<main class="container my-3 my-md-5">
		#view()#
	</main>

	<!--- Footer --->
	<footer class="mt-auto py-3 border-top bg-body-vertical">
        <div class="container d-flex flex-column flex-sm-row justify-content-between align-items-center gap-2">
            <span class="text-muted small">© 2026 <strong class="text-body">Rafael Alves Sequini Martines</strong>. Todos os direitos reservados.</span>
            
            <!-- Redes Sociais -->
            <div class="d-flex gap-3">
                <!-- Substitua o '##' pelo link correto do seu perfil -->
                <a href="https://www.linkedin.com/in/rafael-a-s-martines/" target="_blank" class="text-muted text-hover-primary fs-5" title="LinkedIn">
                    <i class="bi bi-linkedin"></i>
                </a>
                <!-- Substitua o '##' pelo link correto do seu perfil -->
                <a href="https://github.com/rafaelmartines/" target="_blank" class="text-muted text-hover-primary fs-5" title="GitHub">
                    <i class="bi bi-github"></i>
                </a>
            </div>
        </div>
        
		<!-- Menu Flutuante do Seletor de Tema -->
        <div class="dropdown theme-switcher">
            <button class="btn btn-primary btn-lg rounded-circle shadow d-flex align-items-center justify-content-center" 
                    id="bd-theme" type="button" data-bs-toggle="dropdown" aria-expanded="false" style="width: 50px; height: 50px;">
                <i class="bi bi-circle-half" id="theme-icon-active"></i>
            </button>
            <ul class="dropdown-menu dropdown-menu-end shadow" aria-labelledby="bd-theme">
                <li>
                    <button type="button" class="dropdown-item d-flex align-items-center" data-bs-theme-value="light">
                        <i class="bi bi-sun-fill me-2"></i> Light
                    </button>
                </li>
                <li>
                    <button type="button" class="dropdown-item d-flex align-items-center" data-bs-theme-value="dark">
                        <i class="bi bi-moon-stars-fill me-2"></i> Dark
                    </button>
                </li>
                <li>
                    <button type="button" class="dropdown-item d-flex align-items-center" data-bs-theme-value="auto">
                        <i class="bi bi-circle-half me-2"></i> Sistema
                    </button>
                </li>
            </ul>
        </div>
	</footer>

	<!---
		JavaScript
		- Bootstrap
		- Popper
		- Alpine.js
	--->
    <!-- Scripts Necessários -->
        <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
        <script src="https://cdn.datatables.net/2.0.8/js/dataTables.min.js"></script>
        <script src="https://cdn.datatables.net/2.0.8/js/dataTables.bootstrap5.min.js"></script>

        <!-- Lógica de Alternância de Tema -->
        <script>
            (() => {
                'use strict'
                const getStoredTheme = () => localStorage.getItem('theme')
                const setStoredTheme = theme => localStorage.setItem('theme', theme)
                const getPreferredTheme = () => {
                    const storedTheme = getStoredTheme()
                    if (storedTheme) return storedTheme
                    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
                }
                const setTheme = theme => {
                    if (theme === 'auto') {
                        document.documentElement.setAttribute('data-bs-theme', (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'))
                    } else {
                        document.documentElement.setAttribute('data-bs-theme', theme)
                    }
                }
                const updateIcon = (theme) => {
                    const activeIcon = document.querySelector('##theme-icon-active')
                    if (theme === 'light') activeIcon.className = 'bi bi-sun-fill'
                    else if (theme === 'dark') activeIcon.className = 'bi bi-moon-stars-fill'
                    else activeIcon.className = 'bi bi-circle-half'
                }
                setTheme(getPreferredTheme())
                updateIcon(getPreferredTheme())
                window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
                    const storedTheme = getStoredTheme()
                    if (storedTheme !== 'light' && storedTheme !== 'dark') setTheme(getPreferredTheme())
                })
                window.addEventListener('DOMContentLoaded', () => {
                    document.querySelectorAll('[data-bs-theme-value]').forEach(toggle => {
                        toggle.addEventListener('click', () => {
                            const theme = toggle.getAttribute('data-bs-theme-value')
                            setStoredTheme(theme)
                            setTheme(theme)
                            updateIcon(theme)
                        })
                    })
                })
            })()
        </script>

        <!-- Google tag (gtag.js) -->
        <if application.environment eq "production">
            <script async src="https://www.googletagmanager.com/gtag/js?id=G-RNVDS3838M"></script>
            <script>
                window.dataLayer = window.dataLayer || [];
                function gtag(){dataLayer.push(arguments);}
                gtag('js', new Date());

                gtag('config', 'G-RNVDS3838M');
            </script>
        </if>

        <cfif structKeyExists( prc, "scripts" )>
            #prc.scripts#
        </cfif>
	</body>
</html>
</cfoutput>
