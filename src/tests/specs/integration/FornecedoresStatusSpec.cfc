component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {
	function run() {
		describe( "Status e aprovação de fornecedores", function() {
			beforeEach( function() { setup(); } );

			it( "valida dados, categorias e identificadores antes da persistência", function() {
				local.dto = novoDTO();
				local.dto.setNmFornecedor( [] );
				expect( function() { dto.validar(); } ).toThrow( "FornecedorInvalido" );
				local.dto = novoDTO();
				local.dto.setCategorias( [ "1 OR 1=1" ] );
				expect( function() { dto.validar(); } ).toThrow( "FornecedorInvalido" );
				local.dto = novoDTO();
				local.dto.setNrTelefone( "abc5511999999999" );
				expect( function() { dto.validar(); } ).toThrow( "FornecedorInvalido" );
				local.dto = novoDTO();
				local.dto.setTxInstagram( "javascript:alert(1)" );
				expect( function() { dto.validar(); } ).toThrow( "FornecedorInvalido" );
				local.service = getWireBox().getInstance( "FornecedoresService" );
				for ( local.id in [ "", "0", "-1", "2147483648", [], "1 OR 1=1" ] ) {
					expect( function() { service.aprovarFornecedor( id ); } ).toThrow( "FornecedorInvalido" );
				}
			} );

			it( "cadastra Aguardando, mapeia ManyToOne, aprova e filtra os três estados", function() {
				transaction {
					try {
						local.categoria = criarCategoria();
						local.dto = novoDTO( local.categoria );
						local.service = getWireBox().getInstance( "FornecedoresService" );
						local.id = local.service.addFornecedor( local.dto );
						local.entidade = getWireBox().getInstance( "Fornecedor" ).findOrFail( local.id );
						expect( local.entidade.getStatus().getDescricao() ).toBe( "Aguardando" );
						expect( arrayLen( local.entidade.getCategorias() ) ).toBe( 1 );
						local.filtro = novoFiltro( local.categoria );
						expect( local.service.listarFornecedores( local.filtro ).data ).toBeEmpty();
						expect( function() { service.getFornecedor( id ); } ).toThrow( "FornecedorNaoEncontrado" );
						local.service.aprovarFornecedor( local.id );
						expect( local.service.listarFornecedores( local.filtro ).recordsFiltered ).toBe( 1 );
						expect( local.service.getFornecedor( local.id ).cdFornecedor ).toBe( local.id );
						expect( getWireBox().getInstance( "Fornecedor" ).with( "status" ).findOrFail( local.id ).getStatus().getDescricao() ).toBe( "Verificado" );
						expect( function() { service.aprovarFornecedor( id ); } ).toThrow( "FornecedorNaoAguardando" );
						queryExecute( "UPDATE cmscondominio.tb_fornecedores SET status_id = 3 WHERE cd_fornecedor = :id", { id : { value : local.id, cfsqltype : "cf_sql_integer" } } );
						expect( local.service.listarFornecedores( local.filtro ).data ).toBeEmpty();
						expect( function() { service.getFornecedor( id ); } ).toThrow( "FornecedorNaoEncontrado" );
						expect( function() { service.aprovarFornecedor( id ); } ).toThrow( "FornecedorNaoAguardando" );
					} finally { transaction action="rollback"; }
				}
			} );

			it( "recusa categoria inativa sem criar fornecedor e valida paginação e ordenação", function() {
				transaction {
					try {
						local.categoria = criarCategoria();
						queryExecute( "UPDATE cmscondominio.tb_categoria SET in_ativo = false WHERE cd_categoria = :id", { id : { value : local.categoria, cfsqltype : "cf_sql_integer" } } );
						local.dto = novoDTO( local.categoria );
						local.service = getWireBox().getInstance( "FornecedoresService" );
						expect( function() { service.addFornecedor( dto ); } ).toThrow( "FornecedorInvalido" );
						local.registros = queryExecute( "SELECT COUNT(*) AS total FROM cmscondominio.tb_fornecedores WHERE nm_fornecedor = :nome", { nome : { value : local.dto.getNmFornecedor(), cfsqltype : "cf_sql_varchar" } } );
						expect( local.registros.total[ 1 ] ).toBe( 0 );
					} finally { transaction action="rollback"; }
				}
				local.filtro = novoFiltro();
				local.filtro.setLength( 0 );
				expect( function() { service.listarFornecedores( filtro ); } ).toThrow( "FornecedorInvalido" );
				local.filtro.setLength( 10 );
				local.filtro.setOrderDir( "asc; DROP TABLE x" );
				expect( function() { service.listarFornecedores( filtro ); } ).toThrow( "FornecedorInvalido" );
				local.filtro.setOrderDir( "desc" );
				expect( local.service.listarFornecedores( local.filtro ).data ).toBeEmpty();
			} );

			it( "busca nomes com e sem acentos usando a extensão unaccent", function() {
				transaction {
					try {
						local.categoria = criarCategoria();
						local.dto = novoDTO( local.categoria );
						local.dto.setNmFornecedor( "São José Elétrica" );
						local.service = getWireBox().getInstance( "FornecedoresService" );
						local.id = local.service.addFornecedor( local.dto );
						local.service.aprovarFornecedor( local.id );
						local.filtro = novoFiltro( local.categoria );
						for ( local.nome in [ "sao jose", "SÃO JOSÉ", "eletrica", "Elétrica" ] ) {
							local.filtro.setNmFornecedor( local.nome );
							local.resultado = local.service.listarFornecedores( local.filtro );
							expect( local.resultado.recordsFiltered ).toBe( 1 );
							expect( local.resultado.data[ 1 ].cdFornecedor ).toBe( local.id );
						}
						local.filtro.setNmFornecedor( "inexistente" );
						expect( local.service.listarFornecedores( local.filtro ).data ).toBeEmpty();
					} finally { transaction action="rollback"; }
				}
			} );

			it( "pagina e ordena apenas verificados da categoria selecionada", function() {
				transaction {
					try {
						local.categoria = criarCategoria();
						local.service = getWireBox().getInstance( "FornecedoresService" );
						for ( local.nome in [ "A fornecedor temporário", "B fornecedor temporário", "C fornecedor temporário" ] ) {
							local.dto = novoDTO( local.categoria );
							local.dto.setNmFornecedor( local.nome );
							local.id = local.service.addFornecedor( local.dto );
							if ( left( local.nome, 1 ) NEQ "C" ) local.service.aprovarFornecedor( local.id );
						}
						local.filtro = novoFiltro( local.categoria );
						local.filtro.setLength( 1 );
						local.resultado = local.service.listarFornecedores( local.filtro );
						expect( local.resultado.recordsTotal ).toBe( 2 );
						expect( local.resultado.data[ 1 ].nmFornecedor ).toBe( "A fornecedor temporário" );
						local.filtro.setStart( 1 );
						expect( local.service.listarFornecedores( local.filtro ).data[ 1 ].nmFornecedor ).toBe( "B fornecedor temporário" );
						local.filtro.setStart( 0 );
						local.filtro.setOrderDir( "desc" );
						expect( local.service.listarFornecedores( local.filtro ).data[ 1 ].nmFornecedor ).toBe( "B fornecedor temporário" );
					} finally { transaction action="rollback"; }
				}
			} );

			it( "retorna 404 para detalhes inexistentes e recusa aprovação inexistente", function() {
				local.event = get( route = "/fornecedores/2147483647" );
				expect( local.event.getStatusCode() ).toBe( 404 );
				expect( local.event.getCurrentView() ).toBe( "fornecedores/erro" );
				local.service = getWireBox().getInstance( "FornecedoresService" );
				expect( function() { service.aprovarFornecedor( 2147483647 ); } ).toThrow( "FornecedorNaoAguardando" );
			} );

			it( "protege cadastro e aprovação contra visitantes inclusive por evento direto", function() {
				getWireBox().getInstance( "authenticationService@cbauth" ).logout();
				for ( local.rota in [ "/fornecedores/adicionar", "/fornecedores/aprovacao", "/Fornecedores/aprovacao" ] ) {
					setup();
					local.event = get( route = local.rota, renderResults = false );
					expect( local.event.getValue( "relocate_event", "" ) ).toBe( "login" );
				}
				setup();
				local.event = post( route = "/fornecedores/1/aprovar", renderResults = false );
				expect( local.event.getValue( "relocate_event", "" ) ).toBe( "login" );
			} );

			it( "somente administrador aprova; verifica CSRF, formulários, XSS e revogação", function() {
				transaction {
					try {
						local.usuarioId = criarUsuario();
						local.auth = getWireBox().getInstance( "authenticationService@cbauth" );
						local.auth.login( getWireBox().getInstance( "UsuarioService" ).retrieveUserById( local.usuarioId ) );
						expect( function() { execute( event = "Fornecedores.aprovarFornecedor" ); } ).toThrow( "InvalidHTTPMethod" );
						setup();
						local.event = get( route = "/fornecedores/aprovacao" );
						expect( local.event.getStatusCode() ).toBe( 403 );
						setup();
						local.event = post( route = "/fornecedores/1/aprovar", params = { csrfToken : csrfGenerateToken( "fornecedores" ) } );
						expect( local.event.getStatusCode() ).toBe( 403 );
						setup();
						local.event = get( route = "/fornecedores/adicionar" );
						expect( local.event.getCurrentView() ).toBe( "fornecedores/adicionar" );
						local.token = local.event.getPrivateValue( "csrfToken" );
						setup();
						local.event = post( route = "/fornecedores/adicionar" );
						expect( local.event.getStatusCode() ).toBe( 403 );
						setup();
						local.event = post( route = "/fornecedores/adicionar", params = { csrfToken : local.token, nmFornecedor : '<script>alert(1)</script>', categorias : {} } );
						expect( local.event.getStatusCode() ).toBe( 422 );
						expect( local.event.getRenderedContent() ).notToInclude( '<script>alert(1)</script>' );
						local.categoria = criarCategoria();
						local.nome = "Fornecedor teste " & createUUID();
						setup();
						local.event = post( route = "/fornecedores/adicionar", params = { csrfToken : local.token, nmFornecedor : local.nome, nrTelefone : "5511999999999", categorias : local.categoria, status_id : 1, statusId : 1 }, renderResults = false );
						expect( local.event.getValue( "relocate_statusCode", 0 ) ).toBe( 303 );
						local.fornecedor = getWireBox().getInstance( "Fornecedor" ).where( "nmFornecedor", local.nome ).firstOrFail();
						expect( local.fornecedor.getStatus().getDescricao() ).toBe( "Aguardando" );
						queryExecute( "UPDATE cmscondominio.tb_usuarios SET in_administrador = true WHERE cd_usuario = :id", { id : { value : local.usuarioId, cfsqltype : "cf_sql_integer" } } );
						setup();
						local.event = get( route = "/fornecedores/aprovacao" );
						expect( local.event.getRenderedContent() ).toInclude( local.nome );
						setup();
						local.event = post( route = "/fornecedores/#local.fornecedor.getCdFornecedor()#/aprovar" );
						expect( local.event.getStatusCode() ).toBe( 403 );
						setup();
						local.event = post( route = "/fornecedores/#local.fornecedor.getCdFornecedor()#/aprovar", params = { csrfToken : local.token }, renderResults = false );
						expect( local.event.getValue( "relocate_statusCode", 0 ) ).toBe( 303 );
						queryExecute( "UPDATE cmscondominio.tb_usuarios SET in_administrador = false WHERE cd_usuario = :id", { id : { value : local.usuarioId, cfsqltype : "cf_sql_integer" } } );
						setup();
						local.event = get( route = "/fornecedores/aprovacao" );
						expect( local.event.getStatusCode() ).toBe( 403 );
					} finally {
						getWireBox().getInstance( "authenticationService@cbauth" ).logout();
						transaction action="rollback";
					}
				}
			} );
		} );
	}

	private any function novoDTO( numeric categoria = 1 ) {
		local.dto = getWireBox().getInstance( "FornecedorDTO" );
		local.dto.setNmFornecedor( "Fornecedor teste " & createUUID() );
		local.dto.setNrTelefone( "5511999999999" );
		local.dto.setCategorias( [ arguments.categoria ] );
		return local.dto;
	}

	private any function novoFiltro( numeric categoria = 2147483647 ) {
		local.dto = getWireBox().getInstance( "FornecedoresFiltroDTO" );
		local.dto.setNmFornecedor( "" );
		local.dto.setCdCategoria( arguments.categoria );
		local.dto.setOrderColumn( "0" );
		return local.dto;
	}

	private numeric function criarCategoria() {
		return queryExecute( "INSERT INTO cmscondominio.tb_categoria (tx_categoria, in_ativo) VALUES ('Categoria temporária de status', true) RETURNING cd_categoria" ).cd_categoria[ 1 ];
	}

	private numeric function criarUsuario() {
		return queryExecute(
			"INSERT INTO cmscondominio.tb_usuarios (nm_usuario, tx_email, tx_senha_hash) VALUES ('Teste status', :email, 'inutilizavel') RETURNING cd_usuario",
			{ email : { value : lCase( createUUID() ) & "@example.invalid", cfsqltype : "cf_sql_varchar" } }
		).cd_usuario[ 1 ];
	}
}
