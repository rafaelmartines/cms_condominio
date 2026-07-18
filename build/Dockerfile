# Usamos a imagem oficial do CommandBox com suporte a Java 21+ (necessário para Lucee 7)
FROM ortussolutions/commandbox:lucee6-3.16.0

# Informações sobre a sua aplicação
LABEL maintainer="Rafael Alves Sequini Martines <rafael.martines@gmail.com>"

# O Render exige que a aplicação escute em 0.0.0.0
ENV PORT=10000

# 3. Definir o diretório de trabalho da aplicação dentro do container
WORKDIR ${APP_DIR}

# 4. Copiar os arquivos estruturais do ColdBox (box.json) primeiro 
# Isso otimiza o cache de camadas do Docker ao instalar dependências
COPY src/box.json ./

# Instala o Coldbox e outras dependências listadas no seu box.json
RUN box install

# 5. Copiar o restante do código-fonte da aplicação
COPY src/. ./

# 6. Rodar o warmup (pré-aquecimento) para baixar o Lucee 7 e compilar o ColdBox
# Isso evita que o Render sofra timeout na primeira requisição
RUN ${BUILD_DIR}/util/warmup-server.sh

# O Render ignora o EXPOSE e usa o bind interno na porta da variável $PORT, 
# mas mantemos por boas práticas documentacionais.
EXPOSE 10000