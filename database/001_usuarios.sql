-- Execute no mesmo PostgreSQL configurado no datasource cmscondominio.
CREATE TABLE cmscondominio.tb_usuarios (
	cd_usuario integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	nm_usuario varchar(100) NOT NULL,
	tx_email varchar(254) NOT NULL,
	tx_senha_hash varchar(255) NOT NULL,
	ts_criadoem timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT uq_usuarios_email UNIQUE (tx_email),
	CONSTRAINT ck_usuarios_email_normalizado CHECK (tx_email = lower(trim(tx_email)))
);
