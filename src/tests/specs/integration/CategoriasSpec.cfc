component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {

	function run() {
		describe( "Gerenciamento de categorias", function() {
			beforeEach( function() {
				setup();
			} );

			it( "valida IDs e nomes antes de persistir", function() {
				var service = getWireBox().getInstance( "CategoriaService" );
				for ( var id in [ "", "abc", "1 OR 1=1", "-1", "0", "1.5", "2147483648", [] ] ) {
					expect( function() { service.inativarCategoria( id ); } ).toThrow( "CategoriaInvalida" );
				}
				for ( var nome in [ "", "   ", repeatString( "a", 101 ), [] ] ) {
					expect( function() { service.editarCategoria( 1, nome ); } ).toThrow( "CategoriaInvalida" );
					expect( function() { service.criarCategoria( nome ); } ).toThrow( "CategoriaInvalida" );
				}
			} );

			it( "informa quando a categoria não existe", function() {
				var repository = createStub();
				repository.$( "obterPorId", javacast( "null", "" ) );
				repository.$( "editar", false );
				repository.$( "inativar", false );
				var service = prepareMock( new app.models.CategoriaService() );
				service.$property( "categoriaRepository", "variables", repository );
				expect( function() { service.obterCategoria( 1 ); } ).toThrow( "CategoriaNaoEncontrada" );
				expect( function() { service.editarCategoria( 1, "Nome válido" ); } ).toThrow( "CategoriaNaoEncontrada" );
				expect( function() { service.inativarCategoria( 1 ); } ).toThrow( "CategoriaNaoEncontrada" );
			} );

			it( "edita e inativa uma categoria sem alterar vínculos ou a data de criação", function() {
				transaction {
					try {
						var fixture = queryExecute(
							"INSERT INTO cmscondominio.tb_categoria (tx_categoria, ts_criadoem, ts_atualizado) VALUES (:nome, '2020-01-01', '2020-01-01') RETURNING cd_categoria",
							{ nome : { value : "Teste temporário de categorias", cfsqltype : "cf_sql_varchar" } }
						);
						var id = fixture.cd_categoria[ 1 ];
						var fornecedor = queryExecute(
							"INSERT INTO cmscondominio.tb_fornecedores (nm_fornecedor) VALUES (:nome) RETURNING cd_fornecedor",
							{ nome : { value : "Fornecedor temporário de teste", cfsqltype : "cf_sql_varchar" } }
						);
						queryExecute(
							"INSERT INTO cmscondominio.tb_fornecedor_categoria (cd_fornecedor, cd_categoria) VALUES (:fornecedor, :categoria)",
							{
								fornecedor : { value : fornecedor.cd_fornecedor[ 1 ], cfsqltype : "cf_sql_integer" },
								categoria : { value : id, cfsqltype : "cf_sql_integer" }
							}
						);
						var service = getWireBox().getInstance( "CategoriaService" );
						service.editarCategoria( id, "  Elétrica e manutenção  " );
						var editada = service.obterCategoria( id );
						expect( editada.txCategoria ).toBe( "Elétrica e manutenção" );
						expect( editada.inAtivo ).toBeTrue();
						service.inativarCategoria( id );
						service.inativarCategoria( id );
						service.editarCategoria( id, repeatString( "a", 100 ) );
						expect( service.obterCategoria( id ).inAtivo ).toBeFalse();
						expect( arrayLen( service.listarParaGestao().filter( function( categoria ) { return categoria.cdCategoria == id; } ) ) ).toBe( 1 );
						expect( service.obterCategorias().filter( function( categoria ) { return categoria.cdCategoria == id; } ) ).toBeEmpty();
						var entidade = getWireBox().getInstance( "Categoria" ).findOrFail( id );
						expect( dateFormat( entidade.getTsCriadoEm(), "yyyy-mm-dd" ) ).toBe( "2020-01-01" );
						expect( entidade.getTsAtualizado() > entidade.getTsCriadoEm() ).toBeTrue();
						expect( arrayLen( entidade.getFornecedores() ) ).toBe( 1 );
					} finally {
						transaction action="rollback";
					}
				}
			} );

			it( "renderiza formulários, preserva erros e aceita POST com token válido", function() {
				transaction {
					try {
						var fixture = queryExecute(
							"INSERT INTO cmscondominio.tb_categoria (tx_categoria) VALUES (:nome) RETURNING cd_categoria",
							{ nome : { value : '<script>alert("teste")</script>', cfsqltype : "cf_sql_varchar" } }
						);
						var id = fixture.cd_categoria[ 1 ];
						var event = get( route = "/categorias/#id#/editar" );
						expect( event.getCurrentView() ).toBe( "categorias/editar" );
						expect( event.getRenderedContent() ).notToInclude( '<script>alert("teste")</script>' );
						var token = event.getPrivateValue( "csrfToken" );
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
				var service = prepareMock( getWireBox().getInstance( "CategoriaService" ) );
				var listarOriginal = service.listarParaGestao;
				service.$( "listarParaGestao" ).$throws( type = "Database", message = "Detalhe interno de teste" );
				try {
					var event = get( route = "/categorias" );
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
						var event = get( route = "/categorias/adicionar" );
						expect( event.getCurrentView() ).toBe( "categorias/adicionar" );
						expect( event.getRenderedContent() ).toInclude( "Criar categoria" );
						var token = event.getPrivateValue( "csrfToken" );
						var invalido = '<script>alert("teste")</script>' & repeatString( "a", 101 );
						setup();
						event = post( route = "/categorias/adicionar", params = { csrfToken : token, txCategoria : invalido } );
						expect( event.getStatusCode() ).toBe( 422 );
						expect( event.getCurrentView() ).toBe( "categorias/adicionar" );
						expect( event.getPrivateValue( "categoria" ).txCategoria ).toBe( invalido );
						expect( event.getRenderedContent() ).notToInclude( '<script>alert("teste")</script>' );
						setup();
						var nome = "Categoria teste " & createUUID();
						post( route = "/categorias/adicionar", params = { csrfToken : token, txCategoria : "  " & nome & "  " }, renderResults = false );
						var criada = queryExecute(
							"SELECT * FROM cmscondominio.tb_categoria WHERE tx_categoria = :nome",
							{ nome : { value : nome, cfsqltype : "cf_sql_varchar" } }
						);
						expect( criada.recordCount ).toBe( 1 );
						expect( criada.in_ativo[ 1 ] ).toBeTrue();
						expect( isDate( criada.ts_criadoem[ 1 ] ) ).toBeTrue();
						setup();
						event = get( route = "/categorias" );
						expect( event.getRenderedContent() ).toInclude( nome );
						expect( event.getRenderedContent() ).toInclude( 'href="/categorias/adicionar"' );
					} finally {
						transaction action="rollback";
					}
				}
			} );

			it( "bloqueia criação sem CSRF e gravação por GET", function() {
				var event = post( route = "/categorias/adicionar", params = { txCategoria : "Não gravar" } );
				expect( event.getStatusCode() ).toBe( 403 );
				setup();
				expect( function() { execute( event = "Categorias.criar" ); } ).toThrow( "InvalidHTTPMethod" );
			} );

			it( "bloqueia GET direto nas ações de gravação", function() {
				expect( function() { execute( event = "Categorias.salvar" ); } ).toThrow( "InvalidHTTPMethod" );
			} );

			it( "recusa alterações sem token CSRF", function() {
				var event = post( route = "/categorias/1/editar", params = { txCategoria : "Não gravar" } );
				expect( event.getPrivateValue( "erro" ) ).toInclude( "formulário expirou" );
				expect( event.getStatusCode() ).toBe( 403 );
				expect( event.getCurrentView() ).toBe( "categorias/erro" );
			} );

			it( "recusa inativação com token inválido", function() {
				var event = post( route = "/categorias/1/inativar", params = { csrfToken : "invalido" } );
				expect( event.getCurrentView() ).toBe( "categorias/erro" );
			} );

			it( "renderiza a listagem e informa IDs inválidos", function() {
				var event = get( route = "/categorias", renderResults = true );
				expect( event.getRenderedContent() ).toInclude( "Categorias de fornecedores" );
				setup();
				event = get( route = "/categorias/abc/editar", renderResults = true );
				expect( event.getPrivateValue( "erro" ) ).toBe( "Identificador de categoria inválido." );
			} );
		} );
	}

}
