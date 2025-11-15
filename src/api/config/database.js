const { Pool } = require('pg');
require('dotenv').config();

/**
 * Configuração do Pool de Conexão com PostgreSQL/PostGIS
 * 
 * O Pool mantém múltiplas conexões ativas, reutilizando-as
 * para melhorar performance em aplicações com alto volume de requisições.
 */
const pool = new Pool({
  host: process.env.POSTGRES_HOST || 'localhost',
  port: process.env.POSTGRES_PORT || 5432,
  user: process.env.POSTGRES_USER || 'postgres',
  password: process.env.POSTGRES_PASSWORD || 'postgres',
  database: process.env.POSTGRES_DB || 'geospatialdb',
  max: 20, // Número máximo de conexões no pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

/**
 * Evento disparado quando uma conexão é estabelecida
 */
pool.on('connect', () => {
  console.log('✅ Conectado ao PostgreSQL/PostGIS');
});

/**
 * Evento disparado em caso de erro
 */
pool.on('error', (err) => {
  console.error('❌ Erro inesperado no pool do PostgreSQL:', err);
  process.exit(-1);
});

module.exports = pool;

