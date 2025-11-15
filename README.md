## Como Usar Este Projeto

### Opção 1: Setup Local

```bash
# 1. Instalar dependências
npm install

# 2. Configurar variáveis de ambiente
cp env.example .env
# Edite o .env com suas credenciais

# 3. Configurar banco de dados
psql -U postgres -d geospatialdb -f src/sql/create_table.sql
psql -U postgres -d geospatialdb -f src/sql/insert_sample_data.sql

# 4. Iniciar Redis
redis-server

# 5. Iniciar aplicação
npm start
```

### Opção 2: Setup com Docker

```bash
# Inicia PostgreSQL + PostGIS + Redis
docker-compose up -d

# Aguarda serviços iniciarem
sleep 10

# Instala dependências e inicia app
npm install
npm start
```

---

##  Exemplo

O projeto inclui **15 psicólogos cadastrados** em:

- **Goiânia/GO**: 10 psicólogos (diversas regiões)
- **Aparecida de Goiânia/GO**: 2 psicólogos
- **Senador Canedo/GO**: 1 psicólogo
- **Trindade/GO**: 1 psicólogo
- **Anápolis/GO**: 1 psicólogo

Cada registro possui:
- Nome
- CRP (Registro profissional)
- Especialidade
- Localização geográfica (POINT)