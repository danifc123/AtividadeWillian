# Dockerfile para a aplicação Node.js
# (Opcional - usado se você quiser rodar a aplicação também no Docker)

FROM node:16-alpine

# Diretório de trabalho
WORKDIR /app

# Copia arquivos de dependências
COPY package*.json ./

# Instala dependências
RUN npm install

# Copia o código da aplicação
COPY . .

# Expõe a porta da aplicação
EXPOSE 3000

# Comando para iniciar a aplicação
CMD ["npm", "start"]

