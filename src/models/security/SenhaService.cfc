component singleton {

	public string function gerarHash( required string senha ) {
		local.salt = generateSecretKey( "AES", 256 );
		local.iteracoes = 600000;
		local.hash = generatePBKDFKey( "PBKDF2WithHmacSHA256", arguments.senha, local.salt, local.iteracoes, 256 );
		return "pbkdf2-sha256$#local.iteracoes#$#local.salt#$#local.hash#";
	}

	public boolean function verificar( required string senha, required string hash ) {
		local.partes = listToArray( arguments.hash, "$", true );
		if ( arrayLen( local.partes ) NEQ 4 OR local.partes[ 1 ] NEQ "pbkdf2-sha256" ) return false;
		if ( NOT isNumeric( local.partes[ 2 ] ) OR local.partes[ 2 ] NEQ 600000 ) return false;
		local.calculado = generatePBKDFKey( "PBKDF2WithHmacSHA256", arguments.senha, local.partes[ 3 ], local.partes[ 2 ], 256 );
		return createObject( "java", "java.security.MessageDigest" ).isEqual(
			charsetDecode( local.calculado, "UTF-8" ), charsetDecode( local.partes[ 4 ], "UTF-8" )
		);
	}

}
