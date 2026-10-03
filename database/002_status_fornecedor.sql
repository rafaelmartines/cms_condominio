-- Aplicar uma vez, antes de publicar o código, no datasource cmscondominio.
-- Pré-requisitos: tb_fornecedores, suas associações e tb_usuarios já existentes.
BEGIN;
CREATE TABLE cmscondominio.tb_status_fornecedor (
	id integer PRIMARY KEY,
	descricao varchar(20) NOT NULL UNIQUE,
	CONSTRAINT ck_status_fornecedor CHECK (
		(id = 1 AND descricao = 'Verificado') OR
		(id = 2 AND descricao = 'Aguardando') OR
		(id = 3 AND descricao = 'Inativo')
	)
);
INSERT INTO cmscondominio.tb_status_fornecedor (id, descricao)
VALUES (1, 'Verificado'), (2, 'Aguardando'), (3, 'Inativo');
ALTER TABLE cmscondominio.tb_fornecedores ADD COLUMN status_id integer;
-- Preserva a publicação dos registros anteriores à migração.
UPDATE cmscondominio.tb_fornecedores SET status_id = 1;
ALTER TABLE cmscondominio.tb_fornecedores
	ALTER COLUMN status_id SET DEFAULT 2,
	ALTER COLUMN status_id SET NOT NULL,
	ADD CONSTRAINT fk_fornecedor_status FOREIGN KEY (status_id)
		REFERENCES cmscondominio.tb_status_fornecedor (id);
CREATE INDEX ix_fornecedores_status ON cmscondominio.tb_fornecedores (status_id);
-- Nenhuma conta é promovida automaticamente. Conceda acesso explicitamente.
ALTER TABLE cmscondominio.tb_usuarios ADD COLUMN in_administrador boolean NOT NULL DEFAULT false;
COMMIT;
