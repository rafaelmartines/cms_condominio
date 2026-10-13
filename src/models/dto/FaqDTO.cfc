component accessors="true" {

	property name="txPergunta" type="any" default="";
	property name="txResposta" type="any" default="";

	public void function validar() {
		if (
			NOT isSimpleValue( variables.txPergunta ) OR NOT len( trim( variables.txPergunta ) ) OR len(
				trim( variables.txPergunta )
			) GT 300
		) {
			throw( type = "FaqInvalido", message = "Informe uma pergunta com 1 a 300 caracteres." );
		}
		if (
			NOT isSimpleValue( variables.txResposta ) OR NOT len( trim( variables.txResposta ) ) OR len(
				trim( variables.txResposta )
			) GT 10000
		) {
			throw( type = "FaqInvalido", message = "Informe uma resposta com 1 a 10.000 caracteres." );
		}
	}

}
