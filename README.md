# CMS do condomínio

Aplicação para consultar fornecedores, filtrar por nome e categoria, visualizar contatos, comentários e média das notas. Moradores podem enviar indicações de fornecedores e testemunhos por e-mail.

Os formulários enviam mensagens pelo Resend; esses fluxos não gravam fornecedores nem comentários no banco. Sugestões para assembleias e painel de avisos são objetivos futuros, ainda sem implementação no código atual.

## Tecnologias

- Lucee 6, pela imagem `ortussolutions/commandbox:lucee6-3.16.0`.
- ColdBox `8.2.0+35` e WireBox; dependências em `src/box.json`.
- PostgreSQL, com SQL nos repositories e datasource `cmscondominio`.
- Paginação com `cbpaginator` e entidades Quick 12 em `src/models/entities/`. Os repositories atuais continuam usando SQL diretamente.
- Templates CFML, Bootstrap `5.3.3`, Bootstrap Icons `1.11.3`, jQuery `3.7.1` e DataTables `2.0.8`.
- TestBox para testes. Não há pipeline npm configurado.

As bibliotecas da interface e a tradução do DataTables são servidas de `src/includes/vendor/`. O `manifest.json` nessa pasta registra origens, tamanhos e hashes SHA-256; as licenças acompanham os arquivos. O layout também carrega Google Analytics externamente.

## Preparar o ambiente

É necessário ter Podman com suporte a `podman compose`, acesso às imagens e dependências e um PostgreSQL acessível a partir do container. CommandBox no host é opcional se os comandos `box` forem executados no container.

Execute os comandos de Compose na raiz do repositório. Para operações sobre o container (`logs`, `exec`, `restart`, `stop`), use `podman` diretamente com o valor do atributo `container_name` em `docker-compose.yaml`, atualmente `cms_condominio`. Os exemplos abaixo usam esse valor; ajuste-os se o atributo mudar. Use `podman compose` para criar ou remover o ambiente. Prepare a configuração sem sobrescrever um `.env` existente:

```sh
if [ ! -e .env ]; then
  cp .env.example .env
fi
```

Preencha as variáveis com a configuração do seu ambiente:

| Variável | Uso |
| --- | --- |
| `LUCEE_ADMIN_PASSWORD` | Senha administrativa do Lucee |
| `CFCONFIG_DATASOURCES_CMSCONDOMINIO_CLASSNAME` | Classe do driver JDBC |
| `CFCONFIG_DATASOURCES_CMSCONDOMINIO_CONNECTIONSTRING` | String de conexão JDBC |
| `CFCONFIG_DATASOURCES_CMSCONDOMINIO_USERNAME` | Usuário do banco |
| `CFCONFIG_DATASOURCES_CMSCONDOMINIO_PASSWORD` | Senha do banco |
| `CFCONFIG_DATASOURCES_CMSCONDOMINIO_BUNDLENAME` | Bundle do driver |
| `CFCONFIG_DATASOURCES_CMSCONDOMINIO_HOST` | Host acessível pelo container |
| `CFCONFIG_DATASOURCES_CMSCONDOMINIO_PORT` | Porta do PostgreSQL |
| `CFCONFIG_DATASOURCES_CMSCONDOMINIO_DATABASE` | Nome do banco |
| `RESEND_URI` | Endpoint de envio de e-mail |
| `RESEND_KEY` | Chave da integração |
| `RESEND_FROM` | Remetente |
| `RESEND_TO` | Destinatário das indicações e testemunhos |

As quatro variáveis `RESEND_*` ainda não estão em `.env.example`: adicione-as ao `.env` local. Elas são consumidas por `Main.onAppInit`. O Compose define `ENVIRONMENT=development`; fora dele, disponibilize também essa variável ao processo. Não versione credenciais nem compartilhe saídas que expandam o conteúdo do `.env`.

O Compose não cria um banco. É necessário fornecer o schema `cmscondominio`, com `tb_fornecedores`, `tb_categoria`, `tb_fornecedor_categoria` e `tb_comentarios`, conforme as consultas em `src/models/repositories/`. A busca por nome depende de `cmscondominio.unaccent`. Não há migrations ou scripts SQL de criação versionados; obtenha a estrutura compatível antes de usar as páginas.

## Executar localmente

Com CommandBox no host, instale as dependências a partir de `src/`:

```sh
cd src
box install
cd ..
```

Na raiz, inicie o serviço:

```sh
podman compose up --build -d
podman logs -f cms_condominio
```

Se optar por instalar dependências pelo container, execute o comando abaixo com ele em execução. As dependências serão gravadas em `src/` pelo volume; reinicie o serviço após a instalação:

```sh
podman exec -it -w /app cms_condominio box install
podman restart cms_condominio
```

O serviço `lucee` usa o container `cms_condominio`, monta `./src` em `/app` e publica a aplicação em `http://localhost:10000`. Para encerrar o ambiente:

```sh
podman compose down
```

O build local usa o contexto `./build`, que não contém `src/box.json`. Portanto, o `box install` do Dockerfile local não comprova a instalação das dependências da aplicação. Confira `src/coldbox/`, `src/testbox/` e `src/modules/`; se o container não permanecer ativo para a instalação, use CommandBox no host e tente iniciar novamente.

## Páginas e endpoints

| Método | Caminho | Função |
| --- | --- | --- |
| GET | `/` | Listagem de fornecedores com filtros |
| GET | `/fornecedores/adicionar` | Formulário de indicação |
| GET | `/fornecedores/:cdFornecedor` | Detalhes, comentários, média e formulário de testemunho |
| GET | `/categorias` | Gerenciamento de categorias ativas e inativas |
| GET / POST | `/categorias/:cdCategoria/editar` | Formulário e gravação do nome da categoria |
| GET / POST | `/categorias/:cdCategoria/inativar` | Confirmação e inativação da categoria |
| GET | `/api/fornecedores` | Dados da listagem |
| POST | `/api/fornecedores/indicacao` | Envio de indicação por e-mail |
| POST | `/api/fornecedores/:cdFornecedor/testemunho` | Envio de testemunho por e-mail |
| GET | `/healthcheck` | Verificação de conexão com o banco |

Os POSTs de indicação e testemunho recebem JSON convertido em `IndicacaoDTO` e `TestemunhoDTO`; o identificador do fornecedor no testemunho vem da rota. Consulte os DTOs e os formulários em `src/views/fornecedores/` para os campos utilizados. O sucesso do envio retorna um booleano; falhas na integração geram exceção.

O menu **Categorias de fornecedores** dá acesso ao gerenciamento, disponível a todos que acessam o CMS. A lista permite pesquisar, ordenar, paginar e filtrar a situação. A edição aceita nomes de 1 a 100 caracteres, removendo espaços nas extremidades, e mantém a situação atual. A inativação define `in_ativo = false`, preserva os vínculos existentes e retira a categoria das opções dos filtros e formulários. Categorias inativas continuam visíveis nos fornecedores já vinculados. Ambas as operações atualizam `ts_atualizado` via Quick, sem alterar `ts_criadoem`.

Os formulários de categorias enviam POST com token CSRF vinculado à sessão. GET não grava dados. Entradas inválidas retornam 422, categoria inexistente retorna 404 e token inválido retorna 403. Após sucesso, há redirecionamento para a lista e mensagem de confirmação. Não há criação, exclusão ou reativação nesta funcionalidade.

A listagem recebe `filtroNome`, `filtroCategoria`, `start`, `length`, `order[0][column]` e `order[0][dir]`, retornando `data`, `recordsTotal` e `recordsFiltered`. A paginação atual reduz os resultados em memória com `cbpaginator`. Hoje os dois totais usam a contagem filtrada e não há `draw` na resposta. A coluna de categorias também diverge do DTO de ordenação, que a mapeia para empresa; esses pontos exigem revisão conjunta da interface e do backend quando o contrato for alterado.

`/api/echo` e algumas ações em `Main.cfc` são exemplos herdados do template.

## Models Quick ORM

As entidades em `src/models/entities/` refletem as quatro tabelas consultadas no banco configurado pelo `.env`. Todas usam o datasource `cmscondominio`, tabelas qualificadas com o schema e `PostgresGrammar@qb`. Obtenha instâncias pelo WireBox; elas mantêm estado por instância e não são singletons.

| Model | Tabela | Chave | Relacionamentos |
| --- | --- | --- | --- |
| `Fornecedor` | `cmscondominio.tb_fornecedores` | `cdFornecedor` | `categorias()`, `comentarios()` |
| `Categoria` | `cmscondominio.tb_categoria` | `cdCategoria` | `fornecedores()` |
| `Comentario` | `cmscondominio.tb_comentarios` | `cdComentario` | `fornecedor()` |
| `FornecedorCategoria` | `cmscondominio.tb_fornecedor_categoria` | `[cdFornecedor, cdCategoria]` | `fornecedor()`, `categoria()` |

As propriedades usam camelCase e mapeiam explicitamente as colunas originais, incluindo `nrTelefone` como `bigint` e as diferentes grafias dos timestamps. Os IDs das três tabelas principais são `GENERATED ALWAYS AS IDENTITY`: não são enviados em inserts/updates e usam `ReturningKeyType@quick`. A associação usa `NullKeyType@quick` e exige os dois IDs existentes.

Exemplos em um handler ou service com acesso ao WireBox:

```cfml
// Consulta limitada com categorias e comentários carregados antecipadamente.
fornecedores = getInstance( "Fornecedor" )
	.with( [ "categorias", "comentarios" ] )
	.orderBy( "nmFornecedor" )
	.limit( 10 )
	.get();

categorias = getInstance( "Categoria" )
	.where( "inAtivo", true )
	.orderBy( "txCategoria" )
	.get();

// Em um fluxo que já recebeu os dois identificadores:
vinculo = getInstance( "FornecedorCategoria" ).find( [ cdFornecedor, cdCategoria ] );
```

Os campos de data conservam o comportamento do schema: `CURRENT_TIMESTAMP` como default no insert, sem atualização automática de `tsAtualizado`/`tsAtualizadoEm`. Não foram adicionados eventos de timestamp nem migrations. Os fluxos de indicação e testemunho continuam enviando e-mail pelos services existentes.

`BaseEntidade` estende a entidade do Quick e informa a tipagem das duas chaves qualificadas da tabela de associação. Isso evita que o carregamento antecipado do Quick 12 envie IDs como `varchar` para comparação com colunas `integer` no PostgreSQL, sem modificar a dependência instalada.

Referências: [definição de entidades no Quick 12](https://quick.ortusbooks.com/12.0.0/guide/getting-started/defining-an-entity), [relacionamentos](https://quick.ortusbooks.com/12.0.0/guide/relationships) e [componentes no Lucee](https://docs.lucee.org/reference/tags/component.html).

## Verificação e testes

Com o serviço iniciado:

```sh
curl -fsS http://localhost:10000/healthcheck
```

Confira se o corpo é `true`. O endpoint executa `SELECT 1` e pode retornar `false` mesmo com HTTP bem-sucedido. Ele não verifica tabelas, a função `unaccent` ou o Resend.

A suíte TestBox está em `src/tests/specs/`, mas requer preparação antes de ser usada como validação:

- `src/tests/Application.cfc` usa os mappings `coldbox/` e `testbox/`, conforme `src/box.json`, e o datasource `cmscondominio`.
- O ambiente dos testes precisa de configuração ou mocks para banco e bootstrap.
- `MainSpec.cfc` ainda espera `welcomemessage = "Welcome to ColdBox!"`, ausente no handler atual, e contém outros casos do template.
- Testes de indicação e testemunho devem simular o Resend para evitar envio real de mensagens.

Depois de resolver os pré-requisitos do ambiente de testes:

```sh
curl -fsS 'http://localhost:10000/tests/runner.cfm?reporter=json'
```

Para executar somente a integração das entidades Quick:

```sh
curl -fsS 'http://localhost:10000/tests/runner.cfm?reporter=json&bundles=tests.specs.integration.QuickEntitiesSpec'
```

Essa spec executa consultas de leitura, sem inserts, updates, deletes ou envio de e-mail. Verifica colunas, resultado vazio, busca por chave composta e relacionamentos simples e antecipados. As verificações sobre registros existentes dependem de haver dados nas tabelas; a spec não cria fixtures. A persistência não é exercitada contra esse banco.

Para testar o gerenciamento de categorias:

```sh
curl -fsS 'http://localhost:10000/tests/runner.cfm?reporter=json&bundles=tests.specs.integration.CategoriasSpec'
```

Essa spec valida entradas, categorias inexistentes, formulários, CSRF, métodos HTTP e persistência. Os casos de gravação criam categorias e fornecedor temporários em transações com rollback, sem modificar registros existentes nem enviar e-mails. As sequences de identidade podem avançar mesmo com rollback; use um banco de testes para execução recorrente.

Inspecione o relatório: sucesso HTTP não substitui a conferência dos resultados dos testes. Para mudanças visuais, confira a listagem, os filtros, os formulários e o console do navegador em desktop e mobile.

Os scripts de formatação chamam `boxlang format`. Confira a disponibilidade do executável `boxlang` antes de usá-los; a presença de `.cfformat.json` não altera o comando executado. Em `src/`:

```sh
box run-script format:check
```

Para documentação, revise caminhos e comandos e execute `git diff --check`, sem necessidade de iniciar serviços.

## Organização e desenvolvimento

| Caminho | Responsabilidade |
| --- | --- |
| `src/Application.cfc` | Bootstrap, sessões e seleção do datasource |
| `src/config/` | Rotas, ColdBox, WireBox, cache e módulos |
| `src/handlers/` | Páginas e ciclo de vida |
| `src/handlers/api/` | Endpoints JSON e healthcheck |
| `src/models/*Service.cfc` | Orquestração e transformação de dados |
| `src/models/repositories/` | Consultas SQL |
| `src/models/dto/` | Dados de entrada e filtros |
| `src/models/integrations/Resend.cfc` | Integração de e-mail |
| `src/views/`, `src/layouts/` | Interface e scripts das páginas |
| `src/includes/vendor/` | Bibliotecas locais da interface e manifesto |
| `src/tests/` | Runner e specs TestBox |
| `build/`, `docker-compose.yaml` | Imagens e ambiente local |

Siga as orientações de [AGENTS.md](AGENTS.md): mantenha handlers voltados ao HTTP, services à orquestração e repositories ao SQL; preserve nomes de domínio em português. Use parâmetros SQL para valores e listas permitidas para ordenação. O `orderDir` atual ainda é interpolado sem validação explícita; não replique esse padrão. Valide entradas no servidor e codifique a saída conforme o contexto.

Não edite dependências instaladas em `src/coldbox/`, `src/testbox/`, `src/modules/` ou `src/lib/`. Antes de adicionar um módulo, confira se ele já existe em `src/modules/`; se faltar, instale-o pelo CommandBox em `/app` com o container ativo. Ao atualizar bibliotecas da interface, atualize arquivos, licenças, manifesto e referências nas views e no layout em conjunto.

O `src/readme.md` é documentação herdada do template. Este README é o guia do projeto. Os workflows em `src/.github/workflows/` não são workflows ativos na raiz. Os scripts `docker:*` de `src/box.json` não representam o setup atual: os de build e Compose apontam para a pasta `docker/`, que não existe.

## Imagem de produção

O Dockerfile de produção copia `src/` e deve usar a raiz como contexto:

```sh
podman build -f build/Dockerfile -t cms-condominio .
```

A imagem usa Lucee 6, apesar dos comentários que mencionam Lucee 7. O build não provisiona PostgreSQL, schema nem credenciais: disponibilize as variáveis de banco, Resend e ambiente no runtime de destino. O Compose existente está configurado para desenvolvimento.
