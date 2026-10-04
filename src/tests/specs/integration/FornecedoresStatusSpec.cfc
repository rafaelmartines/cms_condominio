component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {
	function run() {
		describe( "Status e aprovação de fornecedores", function() {
			beforeEach( function() { setup(); prepareMock( getWireBox().getInstance( "ErroService" ) ).$( "notificar" ); } );

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
						local.id = novoAguardando( local.dto );
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
						getWireBox().getInstance( "Fornecedor" ).where( "cdFornecedor", local.id ).updateAll( { statusId : 3 } );
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
						getWireBox().getInstance( "Categoria" ).where( "cdCategoria", local.categoria ).updateAll( { inAtivo : false } );
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
						local.id = novoAguardando( local.dto );
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
							local.id = novoAguardando( local.dto );
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

			it( "exclui Aguardando com JWT sem CSRF e remove vínculos", function() {
				transaction {
					try {
						local.categoria = criarCategoria();
						local.service = getWireBox().getInstance( "FornecedoresService" );
						local.id = novoAguardando( novoDTO( local.categoria ) );
						local.event = post( route = "/fornecedores/#local.id#/excluir" );
						expect( local.event.getStatusCode() ).toBe( 401 );
						local.usuarioId = criarUsuario();
						local.tokens = getWireBox().getInstance( "security.JwtAuthenticationService" ).emitirTokens( getWireBox().getInstance( "UsuarioService" ).retrieveUserById( local.usuarioId ) );
						local.headers = { Authorization : "Bearer " & local.tokens.access_token };
						local.verificado = local.service.addFornecedor( novoDTO( local.categoria ) );
						expect( function() { service.excluirFornecedor( verificado ); } ).toThrow( "FornecedorNaoAguardando" );
						setup();
						local.event = get( route = "/fornecedores/aprovacao", headers = local.headers );
						expect( local.event.getRenderedContent() ).toInclude( "/fornecedores/#local.id#/excluir" );
						expect( local.event.getRenderedContent() ).notToInclude( "csrf" );
						setup();
						local.event = post( route = "/fornecedores/#local.id#/excluir", headers = local.headers, renderResults = false );
						expect( local.event.getValue( "relocate_URI", "" ) ).toBe( "/fornecedores/aprovacao" );
						local.registros = queryExecute( "SELECT cd_fornecedor FROM cmscondominio.tb_fornecedores WHERE cd_fornecedor = :id", { id : { value : local.id, cfsqltype : "cf_sql_integer" } } );
						expect( local.registros.recordCount ).toBe( 0 );
						local.vinculos = queryExecute( "SELECT cd_fornecedor FROM cmscondominio.tb_fornecedor_categoria WHERE cd_fornecedor = :id", { id : { value : local.id, cfsqltype : "cf_sql_integer" } } );
						expect( local.vinculos.recordCount ).toBe( 0 );
					} finally { transaction action="rollback"; }
				}
			} );
			it( "protege cadastro e aprovação contra visitantes inclusive por evento direto", function() {
				for ( local.rota in [ "/fornecedores/adicionar", "/fornecedores/aprovacao", "/Fornecedores/aprovacao" ] ) {
					setup();
					local.event = get( route = local.rota );
					expect( local.event.getStatusCode() ).toBe( 401 );
				}
				setup();
				local.event = post( route = "/fornecedores/1/aprovar" );
				expect( local.event.getStatusCode() ).toBe( 401 );
			} );
			it( "cadastra já aprovado com Bearer; ignora status do request e valida dados, XSS e logout", function() {
				transaction {
					try {
						local.usuarioId = criarUsuario();
						local.tokens = getWireBox().getInstance( "security.JwtAuthenticationService" ).emitirTokens( getWireBox().getInstance( "UsuarioService" ).retrieveUserById( local.usuarioId ) );
						local.headers = { Authorization : "Bearer " & local.tokens.access_token };
						setup();
						local.event = get( route = "/fornecedores/adicionar", headers = local.headers );
						expect( local.event.getCurrentView() ).toBe( "fornecedores/adicionar" );
						setup();
						local.event = post( route = "/fornecedores/adicionar", headers = local.headers, params = { nmFornecedor : '<script>alert(1)</script>', categorias : {} } );
						expect( local.event.getStatusCode() ).toBe( 422 );
						expect( local.event.getRenderedContent() ).notToInclude( '<script>alert(1)</script>' );
						local.categoria = criarCategoria();
						local.nome = "Fornecedor teste " & createUUID();
						setup();
						local.event = post( route = "/fornecedores/adicionar", headers = local.headers, params = { nmFornecedor : local.nome, nrTelefone : "5511999999999", categorias : local.categoria, status_id : 1, statusId : 1 }, renderResults = false );
						expect( local.event.getValue( "relocate_statusCode", 0 ) ).toBe( 303 );
						local.fornecedor = getWireBox().getInstance( "Fornecedor" ).where( "nmFornecedor", local.nome ).firstOrFail();
						expect( local.fornecedor.getStatus().getDescricao() ).toBe( "Verificado" );
						expect( getWireBox().getInstance( "FornecedoresService" ).getFornecedor( local.fornecedor.getCdFornecedor() ).nmFornecedor ).toBe( local.nome );
						setup();
						local.event = get( route = "/fornecedores/aprovacao", headers = local.headers );
						expect( local.event.getRenderedContent() ).notToInclude( local.nome );
						setup();
						post( route = "/logout", headers = { Authorization : "Bearer " & local.tokens.refresh_token } );
						setup();
						local.event = get( route = "/fornecedores/aprovacao", headers = local.headers );
						expect( local.event.getStatusCode() ).toBe( 401 );
					} finally { transaction action="rollback"; }
				}
			} );
		} );
	}

	private numeric function novoAguardando( required any dto ) {
		return getWireBox().getInstance( "FornecedoresRepository" ).addFornecedor( arguments.dto.validar() );
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
		return getWireBox().getInstance( "Categoria" ).create( {
			txCategoria : "Categoria temporária de status",
			inAtivo : true
		} ).getCdCategoria();
	}

	private numeric function criarUsuario() {
		return getWireBox().getInstance( "Usuario" ).create( {
			nmUsuario : "Teste status",
			txEmail : lCase( createUUID() ) & "@example.invalid",
			txSenhaHash : "inutilizavel"
		} ).getCdUsuario();
	}
}
