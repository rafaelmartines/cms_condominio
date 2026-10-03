component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {

	function run() {
		describe( "Gerenciamento de categorias", function() {
			beforeEach( function() {
				setup();
				variables.authTeste = prepareMock( getWireBox().getInstance( "authenticationService@cbauth" ) );
				variables.isLoggedInOriginal = variables.authTeste.isLoggedIn;
				variables.getUserOriginal = variables.authTeste.getUser;
				variables.authTeste.$( "isLoggedIn", true );
				variables.authTeste.$( "getUser", new app.models.security.UsuarioAutenticado( { cd_usuario : 1, nm_usuario : "Teste", tx_email : "teste@example.invalid" } ) );
			} );

			afterEach( function() {
				variables.authTeste.isLoggedIn = variables.isLoggedInOriginal;
				variables.authTeste.$property( "isLoggedIn", "variables", variables.isLoggedInOriginal );
				variables.authTeste.getUser = variables.getUserOriginal;
				variables.authTeste.$property( "getUser", "variables", variables.getUserOriginal );
			} );

			it( "valida nomes antes de persistir", function() {
				local.service = getWireBox().getInstance( "CategoriaService" );
				for ( local.nome in [ "", "   ", repeatString( "a", 101 ), [] ] ) {
					expect( function() { service.editarCategoria( 1, nome ); } ).toThrow( "CategoriaInvalida" );
					expect( function() { service.criarCategoria( nome ); } ).toThrow( "CategoriaInvalida" );
				}
			} );

			it( "valida os DTOs com as constraints do cbValidation", function() {
				local.manager = getWireBox().getInstance( "ValidationManager@cbvalidation" );
				local.formulario = getWireBox().getInstance( "CategoriaDTO" );
				expect( manager.validate( target = formulario, profiles = "criar" ).hasErrors( "txCategoria" ) ).toBeTrue();
				for ( local.nome in [ "", "   ", repeatString( "a", 101 ), [], [ "Nome" ], { nome : "Nome" } ] ) {
					formulario.setTxCategoria( nome );
					expect( manager.validate( target = formulario, profiles = "criar" ).hasErrors( "txCategoria" ) ).toBeTrue();
				}
				for ( local.nome in [ "A", "  Elétrica  ", repeatString( "a", 100 ) ] ) {
					formulario.setTxCategoria( nome );
					expect( manager.validate( target = formulario, profiles = "criar" ).hasErrors() ).toBeFalse();
				}
				for ( local.id in [ "", "abc", "0", "-1", "2147483648", [], { id : 1 } ] ) {
					local.formulario.setCdCategoria( local.id );
					expect( local.manager.validate( target = local.formulario, profiles = "editar" ).hasErrors() ).toBeFalse();
				}
			} );

			it( "recusa valores complexos do request sem falha de conversão", function() {
				local.token = csrfGenerateToken( "categorias" );
				for ( local.nome in [ [], [ "Nome" ], { nome : "Nome" } ] ) {
					setup();
					local.event = post( route = "/categorias/adicionar", params = { csrfToken : token, txCategoria : nome } );
					expect( event.getStatusCode() ).toBe( 422 );
					expect( event.getCurrentView() ).toBe( "categorias/adicionar" );
					expect( event.getPrivateValue( "categoria" ).txCategoria ).toBe( "" );
				}
				setup();
				local.event = post( route = "/categorias/adicionar", params = { csrfToken : token } );
				expect( event.getStatusCode() ).toBe( 422 );
			} );

			it( "informa quando a categoria não existe", function() {
				local.repository = createStub();
				repository.$( "obterPorId", javacast( "null", "" ) );
				repository.$( "editar", false );
				repository.$( "inativar", false );
				local.service = prepareMock( new app.models.CategoriaService() );
				service.$property( "categoriaRepository", "variables", repository );
				service.$property( "validationManager", "variables", getWireBox().getInstance( "ValidationManager@cbvalidation" ) );
				expect( function() { service.obterCategoria( 1 ); } ).toThrow( "CategoriaNaoEncontrada" );
				expect( function() { service.editarCategoria( 1, "Nome válido" ); } ).toThrow( "CategoriaNaoEncontrada" );
				expect( function() { service.inativarCategoria( 1 ); } ).toThrow( "CategoriaNaoEncontrada" );
			} );

			it( "edita e inativa uma categoria sem alterar vínculos ou a data de criação", function() {
				transaction {
					try {
						local.fixture = getWireBox().getInstance( "Categoria" ).create( {
							txCategoria : "Teste temporário de categorias",
							tsCriadoEm : createDate( 2020, 1, 1 ),
							tsAtualizado : createDate( 2020, 1, 1 )
						} );
						local.id = local.fixture.getCdCategoria();
						local.fornecedor = getWireBox().getInstance( "Fornecedor" ).create( {
							nmFornecedor : "Fornecedor temporário de teste"
						} );
						getWireBox().getInstance( "FornecedorCategoria" ).create( {
							cdFornecedor : local.fornecedor.getCdFornecedor(),
							cdCategoria : local.id
						} );
						local.service = getWireBox().getInstance( "CategoriaService" );
						service.editarCategoria( id, "  Elétrica e manutenção  " );
						local.editada = service.obterCategoria( id );
						expect( editada.txCategoria ).toBe( "Elétrica e manutenção" );
						expect( editada.inAtivo ).toBeTrue();
						service.inativarCategoria( id );
						service.inativarCategoria( id );
						service.editarCategoria( id, repeatString( "a", 100 ) );
						expect( service.obterCategoria( id ).inAtivo ).toBeFalse();
						expect( arrayLen( service.listarParaGestao().filter( function( categoria ) { return categoria.cdCategoria EQ id; } ) ) ).toBe( 1 );
						expect( service.obterCategorias().filter( function( categoria ) { return categoria.cdCategoria EQ id; } ) ).toBeEmpty();
						local.entidade = getWireBox().getInstance( "Categoria" ).findOrFail( id );
						expect( dateFormat( entidade.getTsCriadoEm(), "yyyy-mm-dd" ) ).toBe( "2020-01-01" );
						expect( entidade.getTsAtualizado() GT entidade.getTsCriadoEm() ).toBeTrue();
						expect( arrayLen( entidade.getFornecedores() ) ).toBe( 1 );
					} finally {
						transaction action="rollback";
					}
				}
			} );

			it( "renderiza formulários, preserva erros e aceita POST com token válido", function() {
				transaction {
					try {
						local.fixture = getWireBox().getInstance( "Categoria" ).create( {
							txCategoria : '<script>alert("teste")</script>'
						} );
						local.id = local.fixture.getCdCategoria();
						local.event = get( route = "/categorias/#id#/editar" );
						expect( event.getCurrentView() ).toBe( "categorias/editar" );
						expect( event.getRenderedContent() ).notToInclude( '<script>alert("teste")</script>' );
						local.token = event.getPrivateValue( "csrfToken" );
						setup();
						event = post( route = "/categorias/#id#/editar", params = { csrfToken : token, txCategoria : "   " } );
						expect( event.getPrivateValue( "erroNome" ) ).toInclude( "1 a 100" );
						expect( event.getStatusCode() ).toBe( 422 );
						expect( event.getPrivateValue( "categoria" ).txCategoria ).toBe( "   " );
						expect( event.getCurrentView() ).toBe( "categorias/editar" );
						setup();
						post( route = "/categorias/#id#/editar", params = { csrfToken : token, txCategoria : "Nome editado" }, renderResults = false );
						expect( getWireBox().getInstance( "CategoriaService" ).obterCategoria( id ).txCategoria ).toBe( "Nome editado" );
						setup();
						event = get( route = "/categorias/#id#/inativar" );
						expect( event.getRenderedContent() ).toInclude( "Confirmar inativação" );
						expect( getWireBox().getInstance( "CategoriaService" ).obterCategoria( id ).inAtivo ).toBeTrue();
						setup();
						post( route = "/categorias/#id#/inativar", params = { csrfToken : token }, renderResults = false );
						expect( getWireBox().getInstance( "CategoriaService" ).obterCategoria( id ).inAtivo ).toBeFalse();
						setup();
						event = get( route = "/categorias/#id#/inativar" );
						expect( event.getRenderedContent() ).toInclude( "Esta categoria já está inativa" );
					} finally {
						transaction action="rollback";
					}
				}
			} );

			it( "trata falhas inesperadas pelo onError sem expor detalhes", function() {
				local.service = prepareMock( getWireBox().getInstance( "CategoriaService" ) );
				local.listarOriginal = service.listarParaGestao;
				service.$( "listarParaGestao" ).$throws( type = "Database", message = "Detalhe interno de teste" );
				try {
					local.event = get( route = "/categorias" );
					expect( event.getStatusCode() ).toBe( 500 );
					expect( event.getCurrentView() ).toBe( "categorias/erro" );
					expect( event.getRenderedContent() ).notToInclude( "Detalhe interno de teste" );
				} finally {
					service.listarParaGestao = listarOriginal;
					service.$property( "listarParaGestao", "variables", listarOriginal );
				}
			} );

			it( "cria categoria ativa pelo formulário e preserva erros de validação", function() {
				transaction {
					try {
						local.event = get( route = "/categorias/adicionar" );
						expect( event.getCurrentView() ).toBe( "categorias/adicionar" );
						expect( event.getRenderedContent() ).toInclude( "Criar categoria" );
						local.token = event.getPrivateValue( "csrfToken" );
						local.invalido = '<script>alert("teste")</script>' & repeatString( "a", 101 );
						setup();
						event = post( route = "/categorias/adicionar", params = { csrfToken : token, txCategoria : invalido } );
						expect( event.getStatusCode() ).toBe( 422 );
						expect( event.getCurrentView() ).toBe( "categorias/adicionar" );
						expect( event.getPrivateValue( "categoria" ).txCategoria ).toBe( invalido );
						expect( event.getRenderedContent() ).notToInclude( '<script>alert("teste")</script>' );
						setup();
						local.nome = "Categoria teste " & createUUID();
						event = post( route = "/categorias/adicionar", params = { csrfToken : token, txCategoria : "  " & nome & "  ", inAtivo : false, cdCategoria : 2147483647, tsCriadoEm : "2000-01-01" }, renderResults = false );
						expect( event.getValue( "relocate_URI", "" ) ).toBe( "/categorias" );
						expect( event.getValue( "relocate_statusCode", 0 ) ).toBe( 303 );
						local.criada = queryExecute(
							"SELECT * FROM cmscondominio.tb_categoria WHERE tx_categoria = :nome",
							{ nome : { value : nome, cfsqltype : "cf_sql_varchar" } }
						);
						expect( criada.recordCount ).toBe( 1 );
						expect( criada.in_ativo[ 1 ] ).toBeTrue();
						expect( isDate( criada.ts_criadoem[ 1 ] ) ).toBeTrue();
						expect( criada.cd_categoria[ 1 ] ).notToBe( 2147483647 );
						expect( dateFormat( criada.ts_criadoem[ 1 ], "yyyy-mm-dd" ) ).notToBe( "2000-01-01" );
						setup();
						event = get( route = "/categorias" );
						expect( event.getRenderedContent() ).toInclude( nome );
						expect( event.getRenderedContent() ).toInclude( 'href="/categorias/adicionar"' );
					} finally {
						transaction action="rollback";
					}
				}
			} );

			it( "conclui a criação no serviço sem falhar após o INSERT", function() {
				transaction {
					try {
						getWireBox().getInstance( "CategoriaService" ).criarCategoria( "Categoria teste " & createUUID() );
					} finally {
						transaction action="rollback";
					}
				}
			} );

			it( "recupera o ID gerado pelo banco na entidade criada", function() {
				transaction {
					try {
						local.nome = "Categoria teste " & createUUID();
						local.categoria = getWireBox().getInstance( "Categoria" ).create( { txCategoria : nome, inAtivo : true } );
						expect( categoria.getCdCategoria() GT 0 ).toBeTrue();
						expect( getWireBox().getInstance( "CategoriaService" ).obterCategoria( categoria.getCdCategoria() ).txCategoria ).toBe( nome );
					} finally {
						transaction action="rollback";
					}
				}
			} );

			it( "bloqueia criação sem CSRF e gravação por GET", function() {
				local.event = post( route = "/categorias/adicionar", params = { txCategoria : "Não gravar" } );
				expect( event.getStatusCode() ).toBe( 403 );
				setup();
				expect( function() { execute( event = "Categorias.criar" ); } ).toThrow( "InvalidHTTPMethod" );
			} );

			it( "bloqueia GET direto nas ações de gravação", function() {
				expect( function() { execute( event = "Categorias.salvar" ); } ).toThrow( "InvalidHTTPMethod" );
			} );

			it( "recusa alterações sem token CSRF", function() {
				local.event = post( route = "/categorias/1/editar", params = { txCategoria : "Não gravar" } );
				expect( event.getPrivateValue( "erro" ) ).toInclude( "formulário expirou" );
				expect( event.getStatusCode() ).toBe( 403 );
				expect( event.getCurrentView() ).toBe( "categorias/erro" );
			} );

			it( "recusa inativação com token inválido", function() {
				local.event = post( route = "/categorias/1/inativar", params = { csrfToken : "invalido" } );
				expect( event.getCurrentView() ).toBe( "categorias/erro" );
			} );

			it( "renderiza a listagem", function() {
				local.event = get( route = "/categorias", renderResults = true );
				expect( event.getRenderedContent() ).toInclude( "Categorias de fornecedores" );
			} );
		} );
	}

}
