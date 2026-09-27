# Orientações para agentes

## Escopo e contexto

Estas orientações se aplicam a todo o repositório. Comunique resultados e escreva documentação em português. Preserve alterações preexistentes do usuário e mantenha cada mudança focada no pedido.

O CMS atende um condomínio. O código atual concentra-se na listagem e consulta de fornecedores, categorias, comentários, notas e envio de indicações e testemunhos por e-mail. Sugestões para assembleias e painel de avisos são objetivos mencionados no README, mas não devem ser tratados como funcionalidades já implementadas.

## Tecnologias e estrutura

- O projeto trabalha com Lucee CFML no backend, com ColdBox `8.2.0+35` e injeção de dependências via WireBox. Dependências em `src/box.json`.
- A fonte obrigatória de conhecimento para sintaxe, funções, tags, configuração e comportamento do Lucee CFML é o site da [documentação oficial do Lucee](https://docs.lucee.org/). Consulte essa documentação e confira a compatibilidade com a versão usada pelo projeto antes de implementar ou alterar código CFML.
- Para implementar ou alterar recursos do ColdBox, consulte também a [documentação oficial do ColdBox](https://coldbox.ortusbooks.com/), selecionando a versão principal (major) correspondente a `dependencies.coldbox` em `src/box.json`. Por exemplo, `8.2.0+35` exige a documentação do ColdBox 8.x; se a dependência mudar para 9.x, consulte a documentação da versão 9.x. Confira o valor no arquivo antes da consulta, sem assumir que a versão mais recente da documentação corresponde à do projeto.
- Os Dockerfiles usam `ortussolutions/commandbox:lucee6-3.16.0`. Comentários que mencionam Lucee 7 não correspondem à imagem declarada.
- PostgreSQL, datasource `cmscondominio` definido em `src/Application.cfc`. Os repositórios usam SQL diretamente; Quick está declarado como dependência, mas não é o padrão de persistência desses repositórios.
- Interface renderizada no servidor com templates `.cfm`, Bootstrap `5.3.3`, Bootstrap Icons `1.11.3`, jQuery `3.7.1` e DataTables `2.0.8` servidos localmente em `src/includes/vendor/`. A tradução `pt-BR.json` do DataTables também é local; o layout ainda carrega Google Analytics externamente. Não há pipeline npm configurado.

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
| `src/includes/vendor/` | Bibliotecas da interface, fontes, licenças e manifesto de origem/integridade |
| `src/tests/` | Runner e specs TestBox |
| `build/`, `docker-compose.yaml` | Imagens e ambiente Podman compatível com Docker Compose |

Não edite dependências instaladas em `src/coldbox/`, `src/testbox/`, `src/modules/` e `src/lib/`. Extensões próprias pertencem ao código da aplicação ou a `src/modules_app/`.

O `README.md` da raiz é o guia operacional do projeto. `src/readme.md` contém documentação herdada do template; não o use como fonte de verdade para o ambiente atual.

## Ambiente e comandos

Execute os comandos Podman na raiz. Use `podman compose` com o arquivo `docker-compose.yaml` para criar ou remover o ambiente. Para operações sobre o container (`logs`, `exec`, `restart`, `stop`), use `podman` diretamente com o valor de `container_name` desse arquivo, atualmente `cms_condominio`; por exemplo, `podman logs -f cms_condominio`. Confira esse atributo antes de executar os comandos e ajuste o nome se ele mudar. Execute comandos CommandBox da aplicação dentro de `src/` no host ou de `/app` no container.

Quando precisar usar um módulo do ColdBox, verifique primeiro se ele já está na pasta de módulos da aplicação (`src/modules/` no host, `/app/modules/` no container). Se estiver ausente, com o container em execução, execute `podman exec -it -w /app {{container_name}} box install {{nome-do-modulo}}`. Substitua os marcadores pelo `container_name` definido em `docker-compose.yaml` (atualmente `cms_condominio`) e pelo nome do módulo. Execute a instalação no diretório `/app`; se necessário, explicite-o com `podman exec -it -w /app cms_condominio box install {{nome-do-modulo}}`.

1. Prepare um `.env` a partir de `.env.example` somente se ele ainda não existir. Não sobrescreva configurações locais.
2. Configure as variáveis `CFCONFIG_DATASOURCES_CMSCONDOMINIO_*` e `LUCEE_ADMIN_PASSWORD`.
3. Configure também `RESEND_URI`, `RESEND_KEY`, `RESEND_FROM` e `RESEND_TO`: são usadas no Compose e no bootstrap, mas ainda não estão no `.env.example`.
4. Disponibilize um PostgreSQL acessível ao runtime. O Compose não fornece serviço de banco e não há scripts de criação do schema ou migrations versionados.

Comandos de referência, sujeitos aos pré-requisitos abaixo:

```sh
# Na raiz: iniciar o serviço local e acompanhar logs
podman compose up --build -d
podman logs -f cms_condominio

# Em src/: instalar dependências com CommandBox no host
box install

# Alternativa na raiz, com o container em execução
podman exec -it -w /app cms_condominio box install

# Em src/: verificar formatação (requer o executável boxlang)
box run-script format:check

# Com o servidor e o ambiente de testes configurados
curl -fsS http://localhost:10000/healthcheck
curl -fsS 'http://localhost:10000/tests/runner.cfm?reporter=json'
```

O serviço local chama-se `lucee`, usa o container `cms_condominio`, publica a porta `10000` e monta `./src` em `/app`. O healthcheck executa `SELECT 1` e retorna um booleano; sucesso HTTP isolado não comprova conexão, confira se o corpo é `true`. Ele não valida tabelas, `unaccent` nem envio de e-mail.

Limitações conhecidas do setup:

- O build local usa contexto `./build`; o `COPY . /app` do `Dockerfile.local` não inclui `src/box.json`. O volume disponibiliza o código apenas na execução. Não presuma que esse build instala as dependências da aplicação; confira a instalação em `src/`.
- Para o Dockerfile de produção, o contexto precisa ser a raiz, pois ele copia `src/`: `podman build -f build/Dockerfile -t cms-condominio .`.
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
- Ao atualizar bibliotecas da interface, preserve os diretórios versionados de `src/includes/vendor/`, licenças, fontes e source maps referenciados. Atualize `manifest.json` (arquivo, origem, SHA-256 e bytes) e as referências no layout e nas views em conjunto; não edite arquivos minificados manualmente.
- Preserve a composição das views via `prc` e os scripts de página capturados em `prc.scripts`. Dentro de `cfoutput`, respeite o escape de `#` literal como `##`.

## Contratos e pontos de atenção

- Rotas de consulta: `GET /api/fornecedores`, `GET /fornecedores/adicionar` e `GET /fornecedores/:cdFornecedor`. A página inicial usa `Main.index`.
- Rotas de envio: `POST /api/fornecedores/indicacao` e `POST /api/fornecedores/:cdFornecedor/testemunho`, com corpo JSON convertido nos respectivos DTOs. O identificador do testemunho vem da rota.
- A listagem recebe `filtroNome`, `filtroCategoria`, `start`, `length`, `order[0][column]` e `order[0][dir]`. O DTO usa `start=0` e `length=10`; valide limites e divisão por zero ao alterar a paginação.
- A consulta carrega os resultados filtrados e usa `Pagination@cbpaginator` para reduzir a coleção em memória; não presuma paginação SQL com `LIMIT/OFFSET`.
- Hoje `recordsTotal` e `recordsFiltered` recebem o mesmo total filtrado, e a resposta não inclui `draw`. A coluna 1 da tela é `categorias`, mas o DTO a mapeia para `f.nm_empresa`. Considere essas divergências ao trabalhar no contrato DataTables, sem corrigi-las fora do escopo.
- `BaseRepository.consulta()` usa `arrayFirst()` para resultados únicos, sem tratamento explícito de coleção vazia. Ao alterar detalhes de fornecedor, cubra também identificador inexistente.
- `/api/echo` e ações de exemplo em `Main.cfc` são remanescentes do template, não funcionalidades de negócio.

## Banco e integrações

Os repositories consultam o schema `cmscondominio`, incluindo `tb_fornecedores`, `tb_categoria`, `tb_fornecedor_categoria` e `tb_comentarios`. A busca por nome depende de `cmscondominio.unaccent`. Não invente schema, credenciais ou migrations ausentes; documente pré-requisitos de alterações de banco.

As configurações `RESEND_*` e `ENVIRONMENT` são lidas em `Main.onAppInit`, registrado em `src/config/Coldbox.cfc`. O Compose define `ENVIRONMENT=development`; a execução fora dele precisa disponibilizar essas variáveis ao processo.

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
