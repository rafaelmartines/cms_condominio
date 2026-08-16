<cfoutput>
<!DOCTYPE html>
<html lang="pt-BR" data-bs-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vivão - Lista de Fornecedores</title>
    
    <!-- Bootstrap 5 CSS -->
    <link href="/includes/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- DataTables Bootstrap 5 Styling CSS -->
    <link href="/includes/css/dataTables.bootstrap5.min.css" rel="stylesheet">
    
    <!-- Bootstrap Icons -->
    <link href="/includes/css/bootstrap-icons/bootstrap-icons.min.css" rel="stylesheet">

    <style>
        body {
            display: flex;
            flex-direction: column;
            min-height: 100vh;
            padding-top: 76px; 
        }
        
        main {
            flex: 1;
        }

        /* === EFEITO TRANSLÚCIDO DINÂMICO === */
        .navbar {
            transition: background-color 0.3s ease, backdrop-filter 0.3s ease, box-shadow 0.3s ease;
        }

        /* Classe aplicada via JS ao scrollar */
        .navbar.scrolled {
            background-color: rgba(var(--bs-body-bg-rgb), 0.75) !important;
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px); /* Suporte para Safari/iOS */
            box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15) !important;
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
<body class="bg-body-tertiary">
	<!---Top NavBar --->
	<header>
		<nav class="navbar fixed-top border-bottom bg-body-vertical" id="mainNavbar">
            <div class="container">
                <a class="navbar-brand fw-bold" href="/"><i class="bi bi-building me-2 text-primary"></i>Vivão</a>
                
                <!-- Grupo de botões alinhados à direita -->
                <div class="d-flex align-items-center gap-2 ms-auto">
                    <!-- Botão Alternador de Tema (Substituiu a div dropdown theme-switcher) -->
                    <button type="button" class="btn btn-outline-secondary d-flex align-items-center justify-content-center" id="btnToggleTheme" aria-label="Alternar Tema" style="width: 40px; height: 40px;">
                        <i class="bi bi-moon-stars-fill" id="themeIcon"></i>
                    </button>

                    <!-- Botão do Menu Hambúrguer -->
                    <button class="navbar-toggler" type="button" data-bs-toggle="offcanvas" data-bs-target="##menuLateralDireito" aria-controls="menuLateralDireito">
                        <span class="navbar-toggler-icon"></span>
                    </button>
                </div>
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
                    <a href="https://uclass.com.br/bn/vbstar/" target="_blank" class="list-group-item list-group-item-action py-3"><i class="bi bi-box-arrow-up-right me-3"></i>Manual do Proprietário</a>
                </div>
            </div>
        </div>
	</header>

	<!---Container And Views --->
	<main class="container my-3 my-md-3">
		#view()#
	</main>

	<!--- Footer --->
	<footer class="mt-3 py-3 border-top bg-body-vertical">
        <div class="container d-flex flex-column flex-sm-row justify-content-between align-items-center gap-2">
            <span class="text-muted small">Desenvolvido por <strong class="text-body">Rafael Alves Sequini Martines</strong>.</span>
            
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
                
                const btnToggle = document.getElementById('btnToggleTheme');
                const themeIcon = document.getElementById('themeIcon');

                // Detecta tema preferido (Local Storage ou Sistema)
                const getPreferredTheme = () => {
                    const storedTheme = localStorage.getItem('theme');
                    if (storedTheme) {
                        return storedTheme;
                    }
                    // Se não houver nada salvo, herda do sistema operacional
                    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
                }

                // Aplica o tema na tag <html> e ajusta o ícone do botão
                const setTheme = (theme) => {
                    document.documentElement.setAttribute('data-bs-theme', theme);
                    localStorage.setItem('theme', theme);

                    if (theme === 'dark') {
                        themeIcon.className = 'bi bi-moon-stars-fill';
                    } else {
                        themeIcon.className = 'bi bi-sun-fill';
                    }
                }

                // Inicializa com a preferência identificada
                setTheme(getPreferredTheme());

                // Ação de clique: Inverte o tema atual
                btnToggle.addEventListener('click', () => {
                    const currentTheme = document.documentElement.getAttribute('data-bs-theme');
                    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
                    setTheme(newTheme);
                });

                // Ouve alterações no sistema operacional do usuário dinamicamente
                window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
                    if (!localStorage.getItem('theme')) {
                        setTheme(e.matches ? 'dark' : 'light');
                    }
                });

                window.addEventListener('scroll', function() {
                    const navbar = document.getElementById('mainNavbar');
                    if (window.scrollY > 20) {
                        navbar.classList.add('scrolled');
                    } else {
                        navbar.classList.remove('scrolled');
                    }
                });
            })();
        </script>

        <!-- Google tag (gtag.js) -->
        <script async src="https://www.googletagmanager.com/gtag/js?id=G-RNVDS3838M"></script>
        <script>
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());

            gtag('config', 'G-RNVDS3838M');
        </script>

        <cfif structKeyExists( prc, "styles" )>
            #prc.styles#
        </cfif>
        <cfif structKeyExists( prc, "scripts" )>
            #prc.scripts#
        </cfif>
	</body>
</html>
</cfoutput>
