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
		<nav class="navbar navbar-expand-lg border-bottom bg-body-vertical">
            <div class="container">
                <a class="navbar-brand fw-bold" href="##"><i class="bi bi-building me-2 text-primary"></i>Vivão</a>
            </div>
        </nav>
	</header>

	<!---Container And Views --->
	<main class="container my-3 my-md-5">
		#view()#
	</main>

	<!--- Footer --->
	<footer>
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

        <!-- Inicialização do DataTables -->
        <script>
            $(document).ready(function() {
                $('##minhaTabela').DataTable({
                    language: {
                        url: 'https://cdn.datatables.net/plug-ins/2.0.8/i18n/pt-BR.json'
                    },
                    pageLength: 5,
                    autoWidth: false, // Evita que o DataTables force larguras fixas nas colunas ocultas
                    responsive: false // Desativado para usar o controle de visualização do próprio Bootstrap
                });
            });
        </script>
	</body>
</html>
</cfoutput>
