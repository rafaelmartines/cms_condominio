component singleton {

	property name="baseRepository" inject="models.repositories.BaseRepotisory";

	public Healthcheck function init() {
		return this;
	}

	public boolean function checkDatabase() renderData="json" {
		return variables.baseRepository.checkDatabase();
	}

}
