component singleton {

    property name="fornecedoresRepository" inject="FornecedoresRepository";

    public FornecedoresService function init() {
        return this;
    }

    public array function getFornecedores() {
        // Simulando a obtenção de dados de fornecedores
        return fornecedoresRepository.getFornecedores();
    }

}
