const { Pool } = require('pg');
require('dotenv').config();

/**
 * Configuração do Pool de Conexão com PostgreSQL/PostGIS
 * 
 * O Pool mantém múltiplas conexões ativas, reutilizando-as
 * para melhorar performance em aplicações com alto volume de requisições.
 */
// Configuração do Pool de Conexão com PostgreSQL/PostGIS
const pool = new Pool({
  host: process.env.POSTGRES_HOST || 'localhost',
  port: parseInt(process.env.POSTGRES_PORT || '5432'),
  user: process.env.POSTGRES_USER || 'postgres',
  password: process.env.POSTGRES_PASSWORD || 'postgres',
  database: process.env.POSTGRES_DB || 'geospatialdb',
  max: 20, // Número máximo de conexões no pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
  ssl: false, // Desabilita SSL para conexões locais
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
  if (err.code === '28P01') {
    console.error('💡 Dica: Verifique as credenciais no arquivo .env');
  } else if (err.code === 'ECONNREFUSED') {
    console.error('💡 Dica: Verifique se o PostgreSQL está rodando (docker-compose up -d)');
  }
  process.exit(-1);
});

/**
 * Testa a conexão com o banco de dados
 */
async function testConnection() {
  try {
    const result = await pool.query('SELECT NOW()');
    console.log('✅ Teste de conexão com PostgreSQL bem-sucedido');
    return true;
  } catch (error) {
    console.error('❌ Falha ao conectar ao PostgreSQL:', error.message);
    if (error.code === '28P01') {
      console.error('💡 Erro de autenticação. Verifique:');
      console.error('   - POSTGRES_USER no arquivo .env');
      console.error('   - POSTGRES_PASSWORD no arquivo .env');
      console.error('   - Se o PostgreSQL está rodando: docker-compose up -d');
    } else if (error.code === 'ECONNREFUSED') {
      console.error('💡 Não foi possível conectar. Verifique:');
      console.error('   - Se o PostgreSQL está rodando: docker-compose up -d');
      console.error('   - POSTGRES_HOST e POSTGRES_PORT no arquivo .env');
    }
    return false;
  }
}

module.exports = pool;
module.exports.testConnection = testConnection;

