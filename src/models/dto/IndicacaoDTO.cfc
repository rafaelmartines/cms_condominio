component accessors="true" {

	property name="categorias"    type="array";
	property name="nmFornecedor"  type="string";
	property name="nmIndicador"   type="string";
	property name="nrApartamento" type="string";
	property name="nrWhatsapp"    type="string";
	property name="txInstagram"   type="string";
	property name="txMotivo"      type="string";
	property name="nrNota" type="numeric" default="5";

	public IndicacaoDTO function init() {
		return this;
	}

	public struct function validar() {
		local.fornecedor = new FornecedorDTO();
		local.fornecedor.setNmFornecedor( isNull( variables.nmFornecedor ) ? "" : variables.nmFornecedor );
		local.fornecedor.setNrTelefone( getNrWhatsapp() );
		local.instagram = isNull( variables.txInstagram ) ? "" : variables.txInstagram;
		local.instagram = reReplaceNoCase( local.instagram, "^https?://(www\.)?instagram\.com/", "" );
		local.fornecedor.setTxInstagram( local.instagram );
		local.fornecedor.setCategorias( isNull( variables.categorias ) ? [] : variables.categorias );
		local.dados = local.fornecedor.validar();
		if ( isNull( variables.nrApartamento ) OR NOT reFind( "^[1-9][0-9]{0,9}$", variables.nrApartamento ) OR variables.nrApartamento GT 2147483647 ) {
			throw( type = "FornecedorInvalido", message = "Informe um apartamento válido." );
		}
		if ( isNull( variables.nmIndicador ) OR NOT len( trim( variables.nmIndicador ) ) OR isNull( variables.txMotivo ) OR NOT len( trim( variables.txMotivo ) ) ) {
			throw( type = "FornecedorInvalido", message = "Informe seu nome e o motivo da indicação." );
		}
		if ( NOT isValid( "integer", variables.nrNota ) OR variables.nrNota LT 1 OR variables.nrNota GT 5 ) {
			throw( type = "FornecedorInvalido", message = "Informe uma nota de 1 a 5." );
		}
		local.dados.nrApartamento = variables.nrApartamento;
		local.dados.nmNome = trim( variables.nmIndicador );
		local.dados.txConteudo = trim( variables.txMotivo );
		local.dados.nrNota = variables.nrNota;
		return local.dados;
	}

	/**
	 * Remove caracteres não numéricos do número de WhatsApp
	 */
	public string function getNrWhatsapp() {
		if ( isNull( variables.nrWhatsapp ) ) return "";
		// Remove tudo que não for dígito
		return reReplace(
			variables.nrWhatsapp,
			"[^0-9]",
			"",
			"all"
		);
	}

}
