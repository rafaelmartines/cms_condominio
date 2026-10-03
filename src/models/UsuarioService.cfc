component singleton implements="cbsecurity.interfaces.IUserService" {

	property name="usuarioRepository" inject="repositories.UsuarioRepository";
	property name="senhaService" inject="security.SenhaService";
	property name="validationManager" inject="ValidationManager@cbvalidation";

	public void function cadastrar( required any usuarioDTO ) {
		local.validacao = variables.validationManager.validate( target = arguments.usuarioDTO, profiles = "cadastro" );
		if ( local.validacao.hasErrors() ) {
			throw( type = "UsuarioInvalido", message = local.validacao.getAllErrors()[ 1 ] );
		}
		variables.usuarioRepository.criar(
			trim( arguments.usuarioDTO.getNmUsuario() ),
			lCase( trim( arguments.usuarioDTO.getTxEmail() ) ),
			variables.senhaService.gerarHash( arguments.usuarioDTO.getTxSenha() )
		);
	}

	public boolean function isValidCredentials( required username, required password ) {
		local.dados = variables.usuarioRepository.obterPorEmail( lCase( trim( arguments.username ) ) );
		if ( structIsEmpty( local.dados ) ) {
			// Mantém o custo de derivação mesmo quando o e-mail não existe.
			variables.senhaService.gerarHash( arguments.password );
			return false;
		}
		return variables.senhaService.verificar( arguments.password, local.dados.tx_senha_hash );
	}

	public any function retrieveUserByUsername( required username ) {
		return paraUsuario( variables.usuarioRepository.obterPorEmail( lCase( trim( arguments.username ) ) ) );
	}

	public any function retrieveUserById( required id ) {
		return paraUsuario( variables.usuarioRepository.obterPorId( arguments.id ) );
	}

	private any function paraUsuario( required struct dados ) {
		if ( structIsEmpty( arguments.dados ) ) {
			throw( type = "UsuarioNaoEncontrado", message = "Usuário não encontrado." );
		}
		return new security.UsuarioAutenticado( arguments.dados );
	}

}
