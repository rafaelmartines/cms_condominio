-- Aplicar uma vez no PostgreSQL do datasource cmscondominio, antes de publicar o FAQ.
-- Pré-requisito: schema cmscondominio existente e permissão para criar tabelas.
BEGIN;
CREATE TABLE cmscondominio.tb_faq (
	cd_faq integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	tx_pergunta varchar(300) NOT NULL,
	tx_resposta text NOT NULL,
	in_ativo boolean NOT NULL DEFAULT true,
	ts_criadoem timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	ts_atualizado timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT ck_faq_pergunta CHECK (char_length(trim(tx_pergunta)) BETWEEN 1 AND 300),
	CONSTRAINT ck_faq_resposta CHECK (char_length(trim(tx_resposta)) BETWEEN 1 AND 10000)
);
CREATE INDEX ix_faq_ativos_pergunta ON cmscondominio.tb_faq (tx_pergunta, cd_faq) WHERE in_ativo = true;
COMMIT;
