component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {
	function run() {
		describe( "Persistência de indicações", function() {
			beforeEach( function() { setup(); } );
			it( "grava fornecedor pendente e comentário sem enviar e-mail", function() {
				transaction {
					try {
						local.categoria = getWireBox().getInstance( "Categoria" ).create( { txCategoria : "Teste indicação", inAtivo : true } ).getCdCategoria();
						local.dto = novoDTO( local.categoria );
						local.service = prepareMock( getWireBox().getInstance( "FornecedoresService" ) );
						local.resend = createStub().$( "enviarEmail", false );
						local.service.$property( "resend", "variables", local.resend );
						expect( local.service.postIndicacao( local.dto ) ).toBeTrue();
						local.registro = queryExecute(
							"SELECT s.descricao, c.nr_apartamento, c.nm_nome, c.tx_conteudo, c.nr_nota, f.tx_instagram
							FROM cmscondominio.tb_fornecedores f JOIN cmscondominio.tb_status_fornecedor s ON s.id = f.status_id
							JOIN cmscondominio.tb_comentarios c ON c.cd_fornecedor = f.cd_fornecedor
							JOIN cmscondominio.tb_fornecedor_categoria fc ON fc.cd_fornecedor = f.cd_fornecedor WHERE fc.cd_categoria = :categoria",
							{ categoria : { value : local.categoria, cfsqltype : "cf_sql_integer" } }
						);
						expect( local.registro.recordCount ).toBe( 1 );
						expect( local.registro.descricao[ 1 ] ).toBe( "Aguardando" );
						expect( local.registro.nr_apartamento[ 1 ] ).toBe( 101 );
						expect( local.registro.nm_nome[ 1 ] ).toBe( "Morador teste" );
						expect( local.registro.tx_conteudo[ 1 ] ).toBe( "Bom atendimento" );
						expect( local.registro.nr_nota[ 1 ] ).toBe( 5 );
						expect( local.registro.tx_instagram[ 1 ] ).toBe( "fornecedor" );
						expect( local.resend.$count( "enviarEmail" ) ).toBe( 0 );
					} finally { transaction action="rollback"; }
				}
			} );
			it( "desfaz o fornecedor quando o comentário falha", function() {
				local.categoria = getWireBox().getInstance( "Categoria" ).create( { txCategoria : "Teste rollback indicação", inAtivo : true } ).getCdCategoria();
				try {
					local.dados = novoDTO( local.categoria ).validar();
					local.dados.nrNota = "nota inválida";
					local.repository = getWireBox().getInstance( "FornecedoresRepository" );
					local.dadosCapturados = local.dados;
					local.repositoryCapturado = local.repository;
					expect( function() { repositoryCapturado.addIndicacao( dadosCapturados ); } ).toThrow();
					local.registros = queryExecute(
						"SELECT COUNT(*) AS total FROM cmscondominio.tb_fornecedor_categoria WHERE cd_categoria = :categoria",
						{ categoria : { value : local.categoria, cfsqltype : "cf_sql_integer" } }
					);
					expect( local.registros.total[ 1 ] ).toBe( 0 );
				} finally {
					getWireBox().getInstance( "Categoria" ).findOrFail( local.categoria ).delete();
				}
			} );

			it( "rejeita apartamento inválido antes de persistir", function() {
				local.dto = novoDTO( 1 );
				local.dto.setNrApartamento( "0" );
				local.dtoCapturado = local.dto;
				expect( function() { dtoCapturado.validar(); } ).toThrow( "FornecedorInvalido" );
			} );
		}	);
	}
	private any function novoDTO( required numeric categoria ) {
		local.dto = getWireBox().getInstance( "IndicacaoDTO" );
		local.dto.setNmFornecedor( "Fornecedor indicação teste" );
		local.dto.setCategorias( [ arguments.categoria ] );
		local.dto.setNrWhatsapp( "+55 (11) 99999-9999" );
		local.dto.setTxInstagram( "https://www.instagram.com/fornecedor" );
		local.dto.setNmIndicador( "Morador teste" );
		local.dto.setNrApartamento( "101" );
		local.dto.setTxMotivo( "Bom atendimento" );
		return local.dto;
	}
}
