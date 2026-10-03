-- Executar no banco do datasource cmscondominio.
-- Requer o schema cmscondominio e permissão para instalar a extensão.
BEGIN;
CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA cmscondominio;
-- IF NOT EXISTS não move uma extensão já instalada em outro schema.
-- Nesse caso, interrompe sem alterar a instalação existente.
DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_extension e
		JOIN pg_namespace n ON n.oid = e.extnamespace
		WHERE e.extname = 'unaccent' AND n.nspname = 'cmscondominio'
	) THEN
		RAISE EXCEPTION 'A extensão unaccent já existe em outro schema. Revise sua localização antes de configurar cmscondominio.unaccent(text).';
	END IF;
END;
$$;
SELECT cmscondominio.unaccent('São José'::text) AS verificacao;
COMMIT;
