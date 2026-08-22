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
