const { createClient } = require('redis');
require('dotenv').config();

/**
 * Configuração do Cliente Redis
 * 
 * Redis é usado como cache para armazenar resultados de consultas geoespaciais,
 * evitando consultas repetidas ao PostGIS e melhorando performance.
 */
const redisClient = createClient({
  socket: {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
  },
});

/**
 * Evento disparado quando conectado ao Redis
 */
redisClient.on('connect', () => {
  console.log('✅ Conectado ao Redis');
});

/**
 * Evento disparado em caso de erro
 */
redisClient.on('error', (err) => {
  console.error('❌ Erro no Redis:', err);
});

/**
 * Inicializa a conexão com o Redis
 */
const connectRedis = async () => {
  try {
    await redisClient.connect();
  } catch (error) {
    console.error('❌ Falha ao conectar ao Redis:', error);
    process.exit(-1);
  }
};

module.exports = {
  redisClient,
  connectRedis,
};

