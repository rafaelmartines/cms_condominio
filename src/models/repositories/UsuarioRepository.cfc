component singleton {

	property name="usuarioProvider" inject="provider:Usuario";

	public struct function obterPorEmail( required string email ) {
		local.resultado = queryExecute(
			"SELECT cd_usuario, nm_usuario, in_administrador, tx_email, tx_senha_hash FROM cmscondominio.tb_usuarios WHERE tx_email = :email",
			{ email : { value : arguments.email, cfsqltype : "cf_sql_varchar" } },
			{ datasource : "cmscondominio", returntype : "array" }
		);
		return arrayLen( local.resultado ) ? local.resultado[ 1 ] : {};
	}

	public struct function obterPorId( required numeric id ) {
		local.resultado = queryExecute(
			"SELECT cd_usuario, nm_usuario, in_administrador, tx_email FROM cmscondominio.tb_usuarios WHERE cd_usuario = :id",
			{ id : { value : arguments.id, cfsqltype : "cf_sql_integer" } },
			{ datasource : "cmscondominio", returntype : "array" }
		);
		return arrayLen( local.resultado ) ? local.resultado[ 1 ] : {};
	}

	public void function criar( required string nome, required string email, required string senhaHash ) {
		local.usuario = variables.usuarioProvider.$get();
		// O builder do Quick mantém ON CONFLICT DO NOTHING sem abortar a transação.
		local.resultado = local.usuario.newQuery().insertIgnore( {
			nmUsuario : local.usuario.generateQueryParamStruct( column = "nmUsuario", value = arguments.nome ),
			txEmail : local.usuario.generateQueryParamStruct( column = "txEmail", value = arguments.email ),
			txSenhaHash : local.usuario.generateQueryParamStruct( column = "txSenhaHash", value = arguments.senhaHash )
		} );
		if ( local.resultado.result.recordCount EQ 0 ) {
			throw( type = "UsuarioDuplicado", message = "Já existe um usuário com este e-mail." );
		}
	}

}
