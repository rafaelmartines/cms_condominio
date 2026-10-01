# CMS do condomínio

Aplicação para consultar fornecedores, filtrar por nome e categoria, visualizar contatos, comentários e média das notas. Moradores podem enviar indicações de fornecedores e testemunhos por e-mail.

Os formulários enviam mensagens pelo Resend; esses fluxos não gravam fornecedores nem comentários no banco. Sugestões para assembleias e painel de avisos são objetivos futuros, ainda sem implementação no código atual.

## Tecnologias

- Lucee 6, pela imagem `ortussolutions/commandbox:lucee6-3.16.0`.
- ColdBox `8.2.0+35` e WireBox; dependências em `src/box.json`.
- PostgreSQL, com datasource `cmscondominio`: consultas complexas usam SQL puro nos repositories; operações de escrita usam QuickORM.
- Paginação com `cbpaginator` e entidades Quick 12 em `src/models/entities/`. As escritas de categorias, fornecedores, vínculos e usuários usam Quick; o cadastro de usuários usa `insertIgnore()` pelo builder da entidade para tratar e-mails duplicados sem abortar a transação.
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

O Compose não cria um banco. É necessário fornecer o schema `cmscondominio`, com `tb_fornecedores`, `tb_categoria`, `tb_fornecedor_categoria` e `tb_comentarios`, conforme as consultas em `src/models/repositories/`. A busca por nome usa a extensão PostgreSQL `unaccent`, instalada no schema `cmscondominio` pelo script `database/003_unaccent.sql`. O script `database/001_usuarios.sql` cria somente a tabela de usuários; obtenha a estrutura das demais tabelas antes de usar as páginas.

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

Ao alterar `src/config/Router.cfc` ou outras configurações do ColdBox, reinicialize a aplicação local para carregar as mudanças, conforme a [documentação do ColdBox](https://coldbox.ortusbooks.com/getting-started/configuration):

```sh
curl -fsS 'http://localhost:10000/?fwreinit=1' -o /dev/null
```

Depois, confira a URL alterada sem `fwreinit`. Os testes de integração inicializam sua própria aplicação e não atualizam as rotas da aplicação usada pelo navegador.

## Páginas e endpoints

| Método | Caminho | Função |
| --- | --- | --- |
| GET | `/` | Listagem de fornecedores com filtros |
| GET | `/fornecedores/indicar` | Indicação por e-mail |
| GET/POST | `/fornecedores/adicionar` | Cadastro no banco (exige login) |
| GET | `/fornecedores/aprovacao` | Pendências (somente administradores) |
| POST | `/fornecedores/:cdFornecedor/aprovar` | Aprovar e publicar (somente administradores) |
| GET | `/fornecedores/:cdFornecedor` | Detalhes, comentários, média e formulário de testemunho |
| GET | `/categorias` | Gerenciamento de categorias ativas e inativas |
| GET / POST | `/categorias/adicionar` | Formulário e criação de categoria ativa |
| GET / POST | `/categorias/:cdCategoria/editar` | Formulário e gravação do nome da categoria |
| GET / POST | `/categorias/:cdCategoria/inativar` | Confirmação e inativação da categoria |
| GET | `/api/fornecedores` | Dados da listagem |
| POST | `/api/fornecedores/indicacao` | Envio de indicação por e-mail |
| POST | `/api/fornecedores/:cdFornecedor/testemunho` | Envio de testemunho por e-mail |
| GET | `/healthcheck` | Verificação de conexão com o banco |

Os POSTs de indicação e testemunho recebem JSON convertido em `IndicacaoDTO` e `TestemunhoDTO`; o identificador do fornecedor no testemunho vem da rota. Consulte os DTOs e os formulários em `src/views/fornecedores/` para os campos utilizados. O sucesso do envio retorna um booleano; falhas na integração geram exceção.

O menu **Categorias de fornecedores** dá acesso ao gerenciamento, disponível apenas a usuários autenticados. A lista permite pesquisar, ordenar, paginar e filtrar a situação. A edição aceita nomes de 1 a 100 caracteres, removendo espaços nas extremidades, e mantém a situação atual. A inativação define `in_ativo = false`, preserva os vínculos existentes e retira a categoria das opções dos filtros e formulários. Categorias inativas continuam visíveis nos fornecedores já vinculados. Ambas as operações atualizam `ts_atualizado` via Quick, sem alterar `ts_criadoem`.

Os formulários de categorias enviam POST com token CSRF vinculado à sessão. GET não grava dados. Entradas inválidas retornam 422, categoria inexistente retorna 404 e token inválido retorna 403. Após sucesso, há redirecionamento para a lista e mensagem de confirmação. A criação gera uma categoria ativa; não há exclusão ou reativação nesta funcionalidade.

A listagem recebe `filtroNome`, `filtroCategoria`, `start`, `length`, `order[0][column]` e `order[0][dir]`, retornando `data`, `recordsTotal` e `recordsFiltered`. A paginação atual reduz os resultados em memória com `cbpaginator`. Hoje os dois totais usam a contagem filtrada e não há `draw` na resposta. A coluna de categorias também diverge do DTO de ordenação, que a mapeia para empresa; esses pontos exigem revisão conjunta da interface e do backend quando o contrato for alterado.

`/api/echo` e algumas ações em `Main.cfc` são exemplos herdados do template.

## Login e cadastro de usuários

O cbSecurity 3.8 usa o cbAuth com autenticação por sessão. O handler `Categorias` tem `secured="true"`; visitantes são redirecionados para `/login`, inclusive nas rotas de gravação. O cadastro (`GET/POST /cadastro`) também exige autenticação. Qualquer usuário autenticado pode gerenciar categorias e cadastrar outros usuários; a aprovação de fornecedores exige a permissão administrativa descrita abaixo. O menu apresenta **Entrar** para visitantes e **Cadastrar usuário** e **Sair** para usuários autenticados.

O login usa e-mail e senha. As senhas têm de 12 a 128 caracteres e são armazenadas como PBKDF2-HMAC-SHA256 com salt aleatório e 600.000 iterações, nunca em texto puro. O login renova a sessão; `POST /logout` exige CSRF e invalida a sessão. Cadastro e login também verificam CSRF. O e-mail é normalizado para minúsculas e tem restrição única no banco. O DTO `UsuarioDTO` concentra as constraints e os perfis `cadastro` e `login`.

Antes do primeiro uso, aplique o SQL no PostgreSQL do datasource. Configure `PGHOST`, `PGPORT`, `PGDATABASE` e `PGUSER`; forneça a senha pelo mecanismo seguro do `psql` (por exemplo, `.pgpass` com permissões restritas). Na raiz:

```sh
psql -X -v ON_ERROR_STOP=1 -f database/001_usuarios.sql
python3 scripts/criar_usuario_inicial.py | psql -X -v ON_ERROR_STOP=1
```

O segundo comando solicita nome, e-mail e senha no terminal, gera o hash e insere a primeira conta somente se a tabela estiver vazia, sob bloqueio transacional. Requer Python 3 e `psql`; não grava arquivos com senhas. Depois, entre em `/login` e use `/cadastro` para novas contas. O cadastro não troca a sessão de quem cadastrou. A instalação e os testes não criam uma conta padrão. Em produção, sirva a aplicação por HTTPS.

As configurações ficam em `src/config/modules/cbauth.cfc` e `cbsecurity.cfc`. `security.AnotacaoAuthValidator` adapta o valor booleano `secured=true` ao validador do cbSecurity 3.8, que o recebe como uma permissão textual; permissões explícitas continuam sendo delegadas ao validador original. Dependências instaladas não foram modificadas.

Teste os fluxos com o banco preparado:

```sh
curl -fsS 'http://localhost:10000/tests/runner.cfm?reporter=json&bundles=tests.specs.integration.AutenticacaoSpec,tests.specs.integration.CategoriasSpec'
```

Os usuários criados pelos testes são revertidos por transação. A suíte de categorias simula uma sessão autenticada; a suíte de autenticação exercita o firewall, cadastro, credenciais, sessão e logout reais.

Referências: [autenticação no cbSecurity](https://coldbox-security.ortusbooks.com/getting-started/configuration/authentication), [GeneratePBKDFKey no Lucee](https://docs.lucee.org/reference/functions/generatepbkdfkey.html) e [armazenamento de senhas na OWASP](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html).

## Busca por nome sem acentos

Instale a extensão oficial `unaccent` no mesmo banco do datasource, após criar o schema `cmscondominio`:

```sh
psql -X -v ON_ERROR_STOP=1 -f database/003_unaccent.sql
```

O script pode ser reaplicado quando a extensão está em `cmscondominio`. Ele verifica a instalação e deve retornar `Sao Jose` para `São José`. Se a extensão já estiver em outro schema, o script interrompe a transação para que o operador revise a localização e os consumidores existentes, sem mover a extensão automaticamente. A conta de instalação precisa das permissões necessárias no banco e no schema; não é necessário concedê-las à conta da aplicação.

A consulta continua usando `cmscondominio.unaccent(text)` nos dois lados da comparação, com parâmetro SQL para o nome. Assim, buscas como `sao jose` encontram `São José`. A instalação corrige a função ausente; os casts para `text` já estavam na consulta.

Referência: [extensão unaccent no PostgreSQL 17](https://www.postgresql.org/docs/17/unaccent.html).

## Cadastro e aprovação de fornecedores

Aplique `database/002_status_fornecedor.sql` uma vez, antes de publicar esta versão, após a criação de `tb_usuarios` por `database/001_usuarios.sql` e das tabelas de fornecedores/categorias já utilizadas pela aplicação:

```sh
psql -X -v ON_ERROR_STOP=1 -f database/002_status_fornecedor.sql
```

A migração usa uma transação, cria `cmscondominio.tb_status_fornecedor` (`id`, `descricao`), adiciona a FK obrigatória `tb_fornecedores.status_id` e mantém todos os fornecedores anteriores como **Verificado**. Os IDs do catálogo são 1 = Verificado, 2 = Aguardando e 3 = Inativo. O default de novos registros é Aguardando. Não reaplique o script; ele não é idempotente. A criação das tabelas de negócio anteriores continua sendo um pré-requisito externo.

A entidade Quick `Fornecedor.statusId` mapeia `status_id`. `Fornecedor.status()` usa `belongsTo`, representando ManyToOne para `StatusFornecedor.id`; `StatusFornecedor.fornecedores()` é o inverso OneToMany. As consultas da lista e dos detalhes públicos exigem Verificado. Registros aguardando, inativos e IDs inexistentes não ficam acessíveis nos detalhes públicos.

`FornecedoresService.addFornecedor()` valida os dados e grava o fornecedor como Aguardando junto com suas categorias ativas, em uma transação. O formulário não aceita status fornecido pelo cliente. `aprovarFornecedor()` faz uma atualização condicional de Aguardando para Verificado; tentativas repetidas, registros inativos ou inexistentes não são aprovados. `listarFornecedores()` preserva o contrato DataTables e retorna apenas verificados. A tela de aprovação mostra os dados para conferência e oferece as ações **Aprovar** e **Excluir**. Não há tela de inativação neste fluxo.

Cadastro, consulta das pendências, aprovação e exclusão exigem autenticação. Qualquer usuário autenticado pode acessar `/fornecedores/aprovacao` e aprovar ou excluir fornecedores com status **Aguardando**, sem permissão de administrador. O menu de aprovação aparece após o login. Os POSTs de cadastro, aprovação e exclusão verificam CSRF. A exclusão remove o fornecedor e seus vínculos em uma transação; fornecedores verificados ou inativos não podem ser excluídos por este fluxo.

O formulário de indicação anterior foi preservado em `/fornecedores/indicar` e continua usando `POST /api/fornecedores/indicacao` para enviar e-mail, sem persistir o fornecedor. O cadastro em `/fornecedores/adicionar` grava no banco e não envia e-mail.

Testes do fluxo:

```sh
curl -fsS 'http://localhost:10000/tests/runner.cfm?reporter=json&bundles=tests.specs.integration.FornecedoresStatusSpec'
```

Os testes exercitam persistência e relacionamento de status, filtros por categoria, visibilidade, CSRF, login, permissão administrativa, revogação e tentativa de envio de status pelo cliente. Os registros temporários são revertidos por transação; sequences podem avançar. Não há envio de e-mail. A busca por nome requer a extensão configurada por `database/003_unaccent.sql`.

Referências de implementação: [handlers no ColdBox 8](https://coldbox.ortusbooks.com/the-basics/event-handlers), [QueryExecute no Lucee](https://docs.lucee.org/reference/functions/queryexecute.html), [transações no Lucee](https://docs.lucee.org/reference/tags/transaction.html) e [CSRFVerifyToken](https://docs.lucee.org/reference/functions/csrfverifytoken.html), compatíveis com o runtime Lucee 6 do projeto.

## Models Quick ORM

As entidades em `src/models/entities/` refletem as tabelas consultadas no banco configurado pelo `.env`. Todas usam o datasource `cmscondominio`, tabelas qualificadas com o schema e `PostgresGrammar@qb`. Obtenha instâncias pelo WireBox; elas mantêm estado por instância e não são singletons.

| Model | Tabela | Chave | Relacionamentos |
| --- | --- | --- | --- |
| `Fornecedor` | `cmscondominio.tb_fornecedores` | `cdFornecedor` | `categorias()`, `comentarios()`, `status()` |
| `StatusFornecedor` | `cmscondominio.tb_status_fornecedor` | `id` | `fornecedores()` |
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

Os campos de data conservam o comportamento do schema: `CURRENT_TIMESTAMP` como default no insert, sem atualização automática de `tsAtualizado`/`tsAtualizadoEm`. Não foram adicionados eventos de timestamp. Os fluxos de indicação e testemunho continuam enviando e-mail pelos services existentes.

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

Siga as orientações de [AGENTS.md](AGENTS.md): mantenha handlers voltados ao HTTP, services à orquestração e repositories ao SQL; preserve nomes de domínio em português. Use parâmetros SQL para valores e listas permitidas para ordenação. A listagem aceita apenas `ASC`/`DESC` na direção de ordenação, início inteiro não negativo e tamanho inteiro de página entre 1 e 100. Valide entradas no servidor e codifique a saída conforme o contexto.

Não edite dependências instaladas em `src/coldbox/`, `src/testbox/`, `src/modules/` ou `src/lib/`. Antes de adicionar um módulo, confira se ele já existe em `src/modules/`; se faltar, instale-o pelo CommandBox em `/app` com o container ativo. Ao atualizar bibliotecas da interface, atualize arquivos, licenças, manifesto e referências nas views e no layout em conjunto.

O `src/readme.md` é documentação herdada do template. Este README é o guia do projeto. Os workflows em `src/.github/workflows/` não são workflows ativos na raiz. Os scripts `docker:*` de `src/box.json` não representam o setup atual: os de build e Compose apontam para a pasta `docker/`, que não existe.

## Imagem de produção

O Dockerfile de produção copia `src/` e deve usar a raiz como contexto:

```sh
podman build -f build/Dockerfile -t cms-condominio .
```

A imagem usa Lucee 6, apesar dos comentários que mencionam Lucee 7. O build não provisiona PostgreSQL, schema nem credenciais: disponibilize as variáveis de banco, Resend e ambiente no runtime de destino. O Compose existente está configurado para desenvolvimento.
