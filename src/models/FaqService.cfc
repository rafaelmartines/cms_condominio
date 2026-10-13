component singleton {

	property name="faqRepository" inject="repositories.FaqRepository";

	public array function listarPublicas( any busca = "" ) {
		if ( NOT isSimpleValue( arguments.busca ) OR len( arguments.busca ) GT 300 ) {
			throw( type = "FaqInvalido", message = "Informe uma busca com até 300 caracteres." );
		}
		return variables.faqRepository.listar( somenteAtivos = true, busca = trim( arguments.busca ) );
	}

	public array function listarParaGestao() {
		return variables.faqRepository.listar( somenteAtivos = false );
	}

	public struct function obterPergunta( required any cdFaq ) {
		validarId( arguments.cdFaq );
		local.resultado = variables.faqRepository.obterPorId( arguments.cdFaq );
		if ( NOT arrayLen( local.resultado ) ) naoEncontrada();
		return local.resultado[ 1 ];
	}

	public numeric function criar( required any dto ) {
		arguments.dto.validar();
		return variables.faqRepository.criar(
			trim( arguments.dto.getTxPergunta() ),
			trim( arguments.dto.getTxResposta() )
		);
	}

	public void function editar( required any cdFaq, required any dto ) {
		validarId( arguments.cdFaq );
		arguments.dto.validar();
		if (
			NOT variables.faqRepository.editar(
				arguments.cdFaq,
				trim( arguments.dto.getTxPergunta() ),
				trim( arguments.dto.getTxResposta() )
			)
		)
			naoEncontrada();
	}

	public void function excluir( required any cdFaq ) {
		definirAtivo( arguments.cdFaq, false );
	}

	public void function reativar( required any cdFaq ) {
		definirAtivo( arguments.cdFaq, true );
	}

	private void function definirAtivo( required any cdFaq, required boolean ativo ) {
		validarId( arguments.cdFaq );
		if ( NOT variables.faqRepository.definirAtivo( arguments.cdFaq, arguments.ativo ) ) naoEncontrada();
	}

	private void function validarId( required any cdFaq ) {
		if (
			NOT isSimpleValue( arguments.cdFaq ) OR NOT reFind( "^[1-9][0-9]{0,9}$", arguments.cdFaq ) OR arguments.cdFaq GT 2147483647
		) {
			throw( type = "FaqInvalido", message = "Identificador de pergunta inválido." );
		}
	}

	private void function naoEncontrada() {
		throw( type = "FaqNaoEncontrado", message = "Pergunta não encontrada." );
	}

}
