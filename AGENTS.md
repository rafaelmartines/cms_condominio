# Orientações para agentes

## Escopo e contexto

Estas orientações se aplicam a todo o repositório. Comunique resultados e escreva documentação em português. Preserve alterações preexistentes do usuário e mantenha cada mudança focada no pedido.

O CMS atende um condomínio. O código atual concentra-se na listagem e consulta de fornecedores, categorias, comentários, notas e envio de indicações e testemunhos por e-mail. Sugestões para assembleias e painel de avisos são objetivos mencionados no README, mas não devem ser tratados como funcionalidades já implementadas.

## Tecnologias e estrutura

- Backend em CFML, com ColdBox `8.1.0+34` e injeção de dependências via WireBox. Dependências em `src/box.json`.
- Os Dockerfiles usam `ortussolutions/commandbox:lucee6-3.16.0`. Comentários que mencionam Lucee 7 não correspondem à imagem declarada.
- PostgreSQL, datasource `cmscondominio` definido em `src/Application.cfc`. Os repositórios usam SQL diretamente; Quick está declarado como dependência, mas não é o padrão de persistência desses repositórios.
- Interface renderizada no servidor com templates `.cfm`, Bootstrap 5, Bootstrap Icons, jQuery e DataTables carregados por CDN. Não há pipeline npm configurado.

| Caminho | Responsabilidade |
| --- | --- |
| `src/Application.cfc` | Bootstrap, datasource, sessões e configuração da aplicação |
| `src/config/` | Rotas, ColdBox, WireBox, cache e módulos |
| `src/handlers/` | Eventos de páginas e ciclo de vida |
| `src/handlers/api/` | Endpoints JSON e healthcheck |
| `src/models/*Service.cfc` | Orquestração e transformação de dados |
| `src/models/repositories/` | Consultas SQL e acesso ao banco |
| `src/models/dto/` | Dados de entrada; filtros em `filter/` |
| `src/models/integrations/Resend.cfc` | Envio de e-mail por HTTP |
| `src/views/`, `src/layouts/` | Páginas, layout compartilhado e scripts de interface |
| `src/tests/` | Runner e specs TestBox |
| `build/`, `docker-compose.yaml` | Imagens e ambiente Docker |

Não edite dependências instaladas em `src/coldbox/`, `src/testbox/`, `src/modules/` e `src/lib/`. Extensões próprias pertencem ao código da aplicação ou a `src/modules_app/`.

## Ambiente e comandos

Execute os comandos Docker na raiz. Execute comandos CommandBox da aplicação dentro de `src/`.

1. Prepare um `.env` a partir de `.env.example` somente se ele ainda não existir. Não sobrescreva configurações locais.
2. Configure as variáveis `CFCONFIG_DATASOURCES_CMSCONDOMINIO_*` e `LUCEE_ADMIN_PASSWORD`.
3. Configure também `RESEND_URI`, `RESEND_KEY`, `RESEND_FROM` e `RESEND_TO`: são usadas no Compose e no bootstrap, mas ainda não estão no `.env.example`.
4. Disponibilize um PostgreSQL acessível ao runtime. O Compose não fornece serviço de banco e não há scripts de criação do schema ou migrations versionados.

Comandos de referência, sujeitos aos pré-requisitos abaixo:

```sh
# Na raiz: iniciar o serviço local e acompanhar logs
docker compose up --build -d
docker compose logs -f lucee

# Em src/: instalar dependências
box install

# Em src/: verificar formatação (requer o executável boxlang)
box run-script format:check

# Com o servidor e o ambiente de testes configurados
curl -fsS http://localhost:10000/healthcheck
curl -fsS 'http://localhost:10000/tests/runner.cfm?reporter=json'
```

O serviço local chama-se `lucee`, publica a porta `10000` e monta `./src` em `/app`. O healthcheck consulta o banco e retorna um booleano; sucesso HTTP isolado não comprova conexão, confira o corpo.

Limitações conhecidas do setup:

- O build local usa contexto `./build`; o `COPY . /app` do `Dockerfile.local` não inclui `src/box.json`. O volume disponibiliza o código apenas na execução. Não presuma que esse build instala as dependências da aplicação; confira a instalação em `src/`.
- Para o Dockerfile de produção, o contexto precisa ser a raiz, pois ele copia `src/`: `docker build -f build/Dockerfile -t cms-condominio .`.
- Os scripts `docker:*` de `src/box.json` apontam para uma pasta `docker/` ausente. Prefira os arquivos reais da raiz e de `build/`.
- Os scripts `format` e `format:check` chamam `boxlang format`, apesar da presença de configuração CFFOrmat. Verifique a ferramenta disponível antes de usá-los; não formate todo o projeto para uma alteração pontual.
- `src/readme.md`, `src/.github/` e partes dos testes vieram do template. Confirme as instruções contra o código. Workflows dentro de `src/.github/workflows/` não são workflows ativos na raiz deste repositório.

## Convenções de implementação

- Siga `src/.editorconfig`: UTF-8, LF, tabs com largura 4; `.yml` usa dois espaços. Preserve o estilo local dos arquivos e consulte `src/.cfformat.json` e `src/.bxformat.json` conforme o formatador utilizado.
- Preserve nomes de domínio em português e convenções existentes, como `cdFornecedor`, `nmFornecedor`, `txConteudo` e sufixos `Service`, `Repository` e `DTO`.
- Mantenha handlers voltados ao HTTP, services à orquestração e repositories ao SQL. Use injeção WireBox e `populateModel()` conforme os exemplos existentes.
- Em componentes `singleton`, mantenha dados por requisição em `local`/`var` e argumentos em `arguments`; não armazene estado de usuário em `variables`.
- Adicione rotas específicas em `src/config/Router.cfc` antes de `:handler/:action?`. Preserve métodos HTTP e contratos consumidos pelas views.
- A listagem `/api/fornecedores` retorna `data`, `recordsTotal` e `recordsFiltered`. Confira conjuntamente handler, DTO, repository, service e DataTables ao alterar filtros, ordenação ou paginação.
- Use parâmetros SQL com `cfsqltype` para valores. Identificadores e direção de ordenação exigem listas permitidas: o DTO já mapeia colunas, mas `orderDir` ainda chega interpolado ao SQL sem validação explícita. Não replique esse padrão inseguro.
- Valide entradas no servidor e codifique conteúdo dinâmico conforme o contexto HTML, atributo, URL ou JavaScript. Validação da interface não substitui validação no backend.
- Preserve a composição das views via `prc` e os scripts de página capturados em `prc.scripts`. Dentro de `cfoutput`, respeite o escape de `#` literal como `##`.

## Banco e integrações

Os repositories consultam o schema `cmscondominio`, incluindo `tb_fornecedores`, `tb_categoria`, `tb_fornecedor_categoria` e `tb_comentarios`. A busca por nome depende de `cmscondominio.unaccent`. Não invente schema, credenciais ou migrations ausentes; documente pré-requisitos de alterações de banco.

Indicações e testemunhos atualmente enviam e-mail pelo Resend; não são inseridos no banco por esses métodos. Preserve essa distinção ao alterar fluxos. Nos testes, substitua o envio por mock/stub para evitar mensagens reais.

Não versione `.env`, tokens, senhas, dumps ou logs com dados pessoais. Documente somente nomes das variáveis e exemplos sem segredos. Não exponha conteúdo de `.env` em respostas ou saídas de diagnóstico.

## Validação e entrega

- Para mudanças de comportamento, use TestBox em `src/tests/specs/`. O exemplo de integração estende `coldbox.system.testing.BaseTestCase` e chama `setup()` antes de cada caso.
- Antes de executar a suíte, verifique `src/tests/Application.cfc`: os mappings apontam para `lib/coldbox` e `lib/testbox`, enquanto `box.json` instala em `coldbox/` e `testbox/`. O ambiente de testes também precisa das configurações ou mocks necessários para banco e bootstrap.
- `MainSpec.cfc` ainda espera `welcomemessage = "Welcome to ColdBox!"`, que o handler atual não define. Não considere a suíte uma comprovação pronta do comportamento atual nem atribua falhas preexistentes à mudança sem análise.
- Para SQL e filtros, cubra entradas inválidas, resultado vazio, paginação e ordenação. Para e-mail, cubra sucesso e falha com integração simulada.
- Para mudanças visuais, confira as telas afetadas em desktop e mobile, os formulários, os filtros e o console do navegador quando houver runtime disponível.
- Para documentação, revise caminhos, comandos e `git diff --check`; não é necessário iniciar serviços externos.
- Na entrega, informe o que mudou, o que foi verificado e eventuais impedimentos. Não declare testes aprovados sem executá-los. Evite corrigir divergências do template fora do escopo solicitado.
