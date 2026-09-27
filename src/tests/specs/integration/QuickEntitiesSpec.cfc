component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {

	function run() {
		describe( "Entidades Quick do schema cmscondominio", function() {
			beforeEach( function() {
				setup();
			} );

			it( "consulta todas as colunas mapeadas e aceita resultado vazio", function() {
				for ( var nome in [ "Fornecedor", "Categoria", "Comentario", "FornecedorCategoria" ] ) {
					var entidade = getWireBox().getInstance( nome );
					expect( entidade.limit( 1 ).get() ).toBeArray();
					expect( getWireBox().getInstance( nome ).whereRaw( "1 = 0" ).get() ).toBeEmpty();
				}
			} );

			it( "preserva os dois campos da chave composta ao buscar uma associação", function() {
				var vinculos = getWireBox().getInstance( "FornecedorCategoria" ).limit( 1 ).get();
				for ( var vinculo in vinculos ) {
					var encontrado = getWireBox().getInstance( "FornecedorCategoria" ).findOrFail(
						[ vinculo.getCdFornecedor(), vinculo.getCdCategoria() ]
					);
					expect( encontrado.isSameAs( vinculo ) ).toBeTrue();
					expect( vinculo.getFornecedor().getCdFornecedor() ).toBe( vinculo.getCdFornecedor() );
					expect( vinculo.getCategoria().getCdCategoria() ).toBe( vinculo.getCdCategoria() );
				}
			} );

			it( "consulta categorias e comentários de um fornecedor com as chaves corretas", function() {
				var fornecedores = getWireBox().getInstance( "Fornecedor" ).limit( 1 ).get();
				for ( var fornecedor in fornecedores ) {
					var categorias = fornecedor.getCategorias();
					var total = queryExecute(
						"SELECT COUNT(*) AS total FROM cmscondominio.tb_fornecedor_categoria WHERE cd_fornecedor = :id",
						{ id : { value : fornecedor.getCdFornecedor(), cfsqltype : "cf_sql_integer" } }
					);
					expect( arrayLen( categorias ) ).toBe( total.total[ 1 ] );
					for ( var comentario in fornecedor.getComentarios() ) {
						expect( comentario.getCdFornecedor() ).toBe( fornecedor.getCdFornecedor() );
						expect( comentario.getFornecedor().isSameAs( fornecedor ) ).toBeTrue();
					}
				}
			} );

			it( "consulta o relacionamento inverso e o carregamento antecipado", function() {
				var categorias = getWireBox().getInstance( "Categoria" ).with( "fornecedores" ).limit( 1 ).get();
				for ( var categoria in categorias ) {
					var total = queryExecute(
						"SELECT COUNT(*) AS total FROM cmscondominio.tb_fornecedor_categoria WHERE cd_categoria = :id",
						{ id : { value : categoria.getCdCategoria(), cfsqltype : "cf_sql_integer" } }
					);
					expect( arrayLen( categoria.getFornecedores() ) ).toBe( total.total[ 1 ] );
				}
				expect(
					getWireBox().getInstance( "Fornecedor" ).with( [ "categorias", "comentarios" ] ).limit( 1 ).get()
				).toBeArray();
			} );
		} );
	}

}
