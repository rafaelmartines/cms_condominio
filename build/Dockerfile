# Base image oficial da Ortus Solutions
FROM ortussolutions/commandbox:lucee7-3.16.0

RUN echo "Aplicação será exposta na porta $PORT"

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia os arquivos da sua aplicação para dentro do container
COPY . /app

# Instala dependências do CommandBox (se houver box.json)
RUN box install

# Expõe a porta padrão do CommandBox (8080)
EXPOSE 8080
