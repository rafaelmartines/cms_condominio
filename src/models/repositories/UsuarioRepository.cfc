component singleton {

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
		local.resultado = queryExecute(
			"INSERT INTO cmscondominio.tb_usuarios (nm_usuario, tx_email, tx_senha_hash)
			VALUES (:nome, :email, :senhaHash) ON CONFLICT (tx_email) DO NOTHING RETURNING cd_usuario",
			{
				nome : { value : arguments.nome, cfsqltype : "cf_sql_varchar" },
				email : { value : arguments.email, cfsqltype : "cf_sql_varchar" },
				senhaHash : { value : arguments.senhaHash, cfsqltype : "cf_sql_varchar" }
			},
			{ datasource : "cmscondominio" }
		);
		if ( local.resultado.recordCount EQ 0 ) {
			throw( type = "UsuarioDuplicado", message = "Já existe um usuário com este e-mail." );
		}
	}

}
