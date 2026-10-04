# CMS do condomínio

Aplicação para consultar fornecedores, filtrar por nome e categoria, visualizar contatos, comentários e média das notas. Moradores podem indicar fornecedores para aprovação, com aviso por e-mail, e enviar testemunhos por e-mail.

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
| GET | `/fornecedores/indicar` | Indicação para aprovação, com aviso por e-mail |
| GET/POST | `/fornecedores/adicionar` | Cadastro no banco (exige login) |
| GET | `/fornecedores/aprovacao` | Pendências (somente administradores) |
| POST | `/fornecedores/:cdFornecedor/aprovar` | Aprovar e publicar (somente administradores) |
| GET | `/fornecedores/:cdFornecedor` | Detalhes, comentários, média e formulário de testemunho |
| GET | `/categorias` | Gerenciamento de categorias ativas e inativas |
| GET / POST | `/categorias/adicionar` | Formulário e criação de categoria ativa |
| GET / POST | `/categorias/:cdCategoria/editar` | Formulário e gravação do nome da categoria |
| GET / POST | `/categorias/:cdCategoria/inativar` | Confirmação e inativação da categoria |
| PUT | `/categorias/:cdCategoria/reativar` | Reativação de categoria, preservando vínculos |
| GET | `/api/fornecedores` | Dados da listagem |
| POST | `/api/fornecedores/indicacao` | Cadastro de indicação aguardando aprovação e aviso via Resend |
| POST | `/api/fornecedores/:cdFornecedor/testemunho` | Envio de testemunho por e-mail |
| GET | `/healthcheck` | Verificação de conexão com o banco |

Os POSTs de indicação e testemunho recebem JSON convertido em `IndicacaoDTO` e `TestemunhoDTO`; o identificador do fornecedor no testemunho vem da rota. Consulte os DTOs e os formulários em `src/views/fornecedores/` para os campos utilizados. O sucesso retorna um booleano; falhas na persistência ou na integração geram exceção.

O menu **Categorias de fornecedores** dá acesso ao gerenciamento, disponível apenas a usuários autenticados. A lista permite pesquisar, ordenar, paginar e filtrar a situação. A edição aceita nomes de 1 a 100 caracteres, removendo espaços nas extremidades, e mantém a situação atual. A inativação define `in_ativo = false`, preserva os vínculos existentes e retira a categoria das opções dos filtros e formulários. Categorias inativas continuam visíveis nos fornecedores já vinculados. Ambas as operações atualizam `ts_atualizado` via Quick, sem alterar `ts_criadoem`.

Os formulários de categorias enviam POST com JWT no header Authorization. GET não grava dados. Entradas inválidas retornam 422, categoria inexistente retorna 404 e autenticação inválida retorna 401. Após sucesso, há redirecionamento para a lista e mensagem de confirmação. A criação gera uma categoria ativa. A listagem permite reativar categorias inativas, preservando o identificador, os vínculos e a data de criação; elas voltam às opções dos formulários e filtros. A reativação usa `PUT /categorias/{id}/reativar`, com JWT de acesso no header `Authorization`, sem corpo obrigatório. Retorna HTTP 200 e JSON `{ "cdCategoria": 1, "txCategoria": "Elétrica", "inAtivo": true }`, inclusive quando a categoria já está ativa. Erros retornam JSON com `erro`: 422 para identificador inválido, 404 para categoria inexistente e 405 para métodos diferentes de PUT (header `Allow: PUT`). O botão atualiza a tabela sem redirecionamento e preserva os filtros. Não há exclusão nesta funcionalidade. A tabela reúne busca por nome, filtro de situação e quantidade por página, com rolagem horizontal em telas pequenas.

A listagem recebe `filtroNome`, `filtroCategoria`, `start`, `length`, `order[0][column]` e `order[0][dir]`, retornando `data`, `recordsTotal` e `recordsFiltered`. A paginação atual reduz os resultados em memória com `cbpaginator`. Hoje os dois totais usam a contagem filtrada e não há `draw` na resposta. A coluna de categorias também diverge do DTO de ordenação, que a mapeia para empresa; esses pontos exigem revisão conjunta da interface e do backend quando o contrato for alterado.

`/api/echo` e algumas ações em `Main.cfc` são exemplos herdados do template.

## Login e cadastro de usuários

O cbSecurity 3.8 usa `security.JwtAuthenticationService`, que autentica exclusivamente por `Authorization: Bearer <token>`. Cookies, sessão, corpo e parâmetros de URL não substituem esse header. As rotas com `secured="true"` verificam assinatura HS256, emissor, expiração, revogação e existência do usuário; refresh tokens não autorizam páginas protegidas. Qualquer usuário autenticado pode gerenciar categorias e cadastrar outros usuários. Os requisitos de fornecedores estão descritos abaixo.

`POST /login` recebe JSON com `txEmail` (usuário) e `txSenha`. Após validar as credenciais, retorna `access_token`, `refresh_token`, `token_type`, `expires_at` e `refresh_expires_at`; os prazos são timestamps Unix em segundos. Não exige nem devolve `csrf_token`. As senhas têm de 12 a 128 caracteres e são armazenadas como PBKDF2-HMAC-SHA256 com salt aleatório e 600.000 iterações. O e-mail é normalizado para minúsculas e tem restrição única no banco. O DTO `UsuarioDTO` concentra as constraints.

A interface armazena o par no `localStorage` em `cms.jwt` e envia o acesso em `Authorization` nas chamadas de mesma origem. `fetch`, chamadas jQuery/DataTables e formulários usam esse fluxo; requests externos não recebem o JWT. O storage anterior (`cms.access_token`) e os cookies antigos não autenticam a aplicação: faça novo login após atualizar. O armazenamento local é acessível aos scripts da mesma origem; mantenha somente scripts confiáveis e codifique conteúdo dinâmico.

As páginas continuam sendo renderizadas por CFML. A navegação autenticada carrega HTML com `fetch` e Bearer, atualiza o histórico e executa os scripts de página. Abrir uma rota protegida diretamente ou recarregá-la entrega somente uma tela de espera pública; o JavaScript busca o conteúdo com o token do storage. Sem token, direciona para `/login`. O handler protegido não executa durante essa resposta inicial. Chamadas sem Bearer ou com token inválido recebem 401. A sessão permanece somente para mensagens flash, sem identidade de autenticação. Formulários protegidos não contêm nem verificam CSRF, pois cookies não concedem acesso.

Antes do primeiro uso, aplique o SQL no PostgreSQL do datasource. Configure `PGHOST`, `PGPORT`, `PGDATABASE` e `PGUSER`; forneça a senha pelo mecanismo seguro do `psql` (por exemplo, `.pgpass` com permissões restritas). Na raiz:

```sh
psql -X -v ON_ERROR_STOP=1 -f database/001_usuarios.sql
python3 scripts/criar_usuario_inicial.py | psql -X -v ON_ERROR_STOP=1
```

O segundo comando solicita nome, e-mail e senha no terminal, gera o hash e insere a primeira conta somente se a tabela estiver vazia, sob bloqueio transacional. Requer Python 3 e `psql`; não grava arquivos com senhas. Depois, entre em `/login` e use `/cadastro` para novas contas. O cadastro mantém o JWT de quem cadastrou. A instalação e os testes não criam uma conta padrão. Em produção, sirva a aplicação por HTTPS.

Configure `JWT_SECRET` com pelo menos 32 caracteres aleatórios no ambiente do processo (o Compose repassa a variável). Fora de `ENVIRONMENT=development`, o segredo é obrigatório; em desenvolvimento, se vazio, o cbSecurity gera uma chave temporária. Nunca versione o valor. Use HTTPS em produção. Depois de alterar variáveis no `.env`, recrie o serviço com `podman compose up -d`.

O acesso dura 15 minutos. `POST /autenticacao/renovar` recebe o **refresh token em `Authorization: Bearer`**, sem CSRF ou cookie, e retorna um novo par. A rotação revoga o acesso e o refresh anteriores e mantém o prazo absoluto de 7 dias desde o login. A interface tenta renovar 30 segundos antes da expiração, antes de chamadas com acesso expirado e uma vez após receber 401. Web Locks coordena a renovação entre abas quando disponível. `GET /autenticacao/token` valida o acesso enviado no header e retorna `{"autenticado":true}`; não recupera tokens de cookies.

`POST /logout` recebe um JWT válido no header (a interface envia o refresh para permitir logout com acesso expirado) e revoga o par atual. A interface remove `cms.jwt` após sucesso ou após 401, quando o servidor já não aceita esse token. Falhas de rede preservam os dados para tentar novamente.

Os tokens e seus registros de revogação usam CacheBox em memória. Reiniciar/reinicializar a aplicação ou perder entradas do cache exige novo login. O armazenamento e o bloqueio de rotação atendem uma instância; múltiplas instâncias exigem armazenamento compartilhado e rotação atômica nesse armazenamento.

As configurações JWT ficam em `src/config/modules/cbsecurity.cfc` e `src/config/Coldbox.cfc`. `cbauth.cfc` permanece como configuração do módulo instalado, mas não fornece a autenticação da aplicação. `security.AnotacaoAuthValidator` adapta o valor booleano `secured=true` ao validador do cbSecurity 3.8, que o recebe como uma permissão textual; permissões explícitas continuam sendo delegadas ao validador original. Dependências instaladas não foram modificadas.

Teste os fluxos com o banco preparado:

```sh
curl -fsS 'http://localhost:10000/tests/runner.cfm?reporter=json&bundles=tests.specs.integration.JwtSpec,tests.specs.integration.AutenticacaoSpec,tests.specs.integration.CategoriasSpec,tests.specs.integration.FornecedoresStatusSpec'
```

Os usuários criados pelos testes são revertidos por transação. A suíte de categorias simula o serviço de autenticação; a suíte de autenticação exercita o firewall, cadastro, credenciais, JWT e logout reais. `JwtSpec` simula usuários sem consultar o banco e cobre assinatura, emissor, Bearer, rejeição de cookies/URL, expiração, separação entre acesso e renovação, rotação, reutilização e revogação.

Referências JWT: [serviço JWT do cbSecurity](https://coldbox-security.ortusbooks.com/v2.x-3/jwt/jwt-services), [renovação de tokens](https://coldbox-security.ortusbooks.com/v2.x-3/jwt/refresh-tokens), [headers de requisição no Lucee 6](https://docs.lucee.org/reference/functions/gethttprequestdata.html) e [renderização JSON no ColdBox 8](https://coldbox.ortusbooks.com/the-basics/event-handlers/rendering-data).

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

`FornecedoresService.addFornecedor()` valida os dados e grava o fornecedor como **Verificado** junto com suas categorias ativas, em uma transação. O cadastro autenticado em `/fornecedores/adicionar` publica imediatamente fornecedores já aprovados. O formulário não aceita status fornecido pelo cliente. `aprovarFornecedor()` faz uma atualização condicional de Aguardando para Verificado; tentativas repetidas, registros inativos ou inexistentes não são aprovados. `listarFornecedores()` preserva o contrato DataTables e retorna apenas verificados. A tela de aprovação mostra os dados para conferência e oferece as ações **Aprovar** e **Excluir**. Não há tela de inativação neste fluxo.

Cadastro, consulta das pendências, aprovação e exclusão exigem autenticação. Qualquer usuário autenticado pode acessar `/fornecedores/aprovacao` e aprovar ou excluir fornecedores com status **Aguardando**, sem permissão de administrador. O menu de aprovação aparece após o login. Os POSTs de cadastro, aprovação e exclusão exigem JWT de acesso válido no header Authorization, sem CSRF. A exclusão remove o fornecedor e seus vínculos em uma transação; fornecedores verificados ou inativos não podem ser excluídos por este fluxo.

O formulário de indicação anterior foi preservado em `/fornecedores/indicar` e continua usando `POST /api/fornecedores/indicacao` para gravar o fornecedor como **Aguardando** (aguardando aprovação), suas categorias e um comentário, além de enviar um aviso de fornecedor aguardando aprovação por `Resend.enviarEmail()`, para `RESEND_TO`. Uma exceção ou retorno falso do envio desfaz a gravação, permitindo nova tentativa. O envio HTTP ocorre dentro da transação de gravação e pode aguardar até o timeout do Resend (10 segundos). Banco e serviço externo não compartilham uma transação: uma falha de confirmação no banco após o envio ou um timeout após a aceitação do e-mail pode deixar um aviso já enviado. O comentário usa `nrApartamento`, `nmIndicador` como `nmNome`, `txMotivo` como `txConteudo` e a nota (padrão 5). O cadastro em `/fornecedores/adicionar` grava no banco e não envia e-mail.

Testes do fluxo:

```sh
curl -fsS 'http://localhost:10000/tests/runner.cfm?reporter=json&bundles=tests.specs.integration.FornecedoresStatusSpec'
```

Os testes exercitam persistência e relacionamento de status, filtros por categoria, visibilidade, CSRF, login, permissão administrativa, revogação e tentativa de envio de status pelo cliente. Os registros temporários são revertidos por transação; sequences podem avançar. Não há envio de e-mail. A busca por nome requer a extensão configurada por `database/003_unaccent.sql`.

Referências de implementação: [handlers no ColdBox 8](https://coldbox.ortusbooks.com/the-basics/event-handlers), [QueryExecute no Lucee](https://docs.lucee.org/reference/functions/queryexecute.html), [transações no Lucee](https://docs.lucee.org/reference/tags/transaction.html), compatíveis com o runtime Lucee 6 do projeto.

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

Os campos de data conservam o comportamento do schema: `CURRENT_TIMESTAMP` como default no insert, sem atualização automática de `tsAtualizado`/`tsAtualizadoEm`. Não foram adicionados eventos de timestamp. Indicações gravam fornecedor e comentário; testemunhos continuam enviando e-mail.

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
- Testes de testemunho devem simular o Resend para evitar envio real de mensagens.

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

Para conferir também a reativação por HTTP real, execute `CategoriasHttpSpec` com o servidor local ativo. Ela faz login com um usuário temporário, envia duas requisições `PUT /categorias/{id}/reativar` e confere HTTP 200, JSON e a situação ativa no banco. Os registros temporários são gravados fora de uma transação externa para ficarem visíveis à conexão HTTP, e removidos ao final; o teste também encerra o acesso temporário.

```sh
curl -fsS 'http://localhost:10000/tests/runner.cfm?reporter=json&bundles=tests.specs.integration.CategoriasHttpSpec,tests.specs.integration.CategoriasSpec'
```

Após alterar `src/config/Router.cfc`, recarregue o ColdBox local antes de testar a aplicação: `curl -fsS 'http://localhost:10000/healthcheck?fwreinit=1'`. Esse comando exige a configuração local de reinit sem senha e reinicializa a aplicação. As specs usam uma aplicação virtual recém-inicializada; elas podem passar enquanto o servidor ainda mantém rotas antigas em memória. Confira se o corpo do healthcheck é `true`.

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

## Notificação de erros

O interceptor `NotificacaoErros` notifica respostas HTTP de erro (400–599) e exceções não tratadas, inclusive nas APIs, usando `Resend.enviarEmail()`. O destinatário é `RESEND_TO`, com as mesmas configurações `RESEND_URI`, `RESEND_KEY` e `RESEND_FROM` dos demais e-mails. Há no máximo uma tentativa por requisição. Falhas de envio são registradas no LogBox e não substituem o erro original nem geram novas notificações; a chamada HTTP ao Resend tem timeout de 10 segundos.

Cada mensagem anexa um arquivo `.log` em Base64 com o registro daquela ocorrência: identificador, horário, status HTTP, evento, método, tipo da exceção e até 50 localizações de arquivo/linha da pilha. O mesmo registro é enviado ao LogBox. Não são anexados arquivos completos do container, corpo/headers da requisição, cookies, SQL, valores do formulário ou mensagens brutas da exceção, que podem conter senhas, tokens e dados pessoais. Respostas de validação ou autenticação também geram e-mail. Erros do proxy, do container ou anteriores ao bootstrap do ColdBox não passam por esse interceptor.

Os testes em `src/tests/specs/integration/ErrosSpec.cfc` simulam o Resend para verificar anexo, ausência de segredos, deduplicação, falha de envio e integração com o tratamento HTTP, sem enviar mensagens reais.
