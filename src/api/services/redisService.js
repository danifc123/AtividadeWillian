const { redisClient } = require('../config/redis');

/**
 * Serviço responsável pelas operações de cache com Redis
 * 
 * Redis é um banco de dados chave-valor em memória, extremamente rápido,
 * ideal para cache de consultas frequentes.
 */
class RedisService {
  /**
   * Gera a chave de cache baseada nos parâmetros de busca geoespacial
   * 
   * Padrão: geo:search:lat:<lat>:lng:<lng>:radius:<km>
   * 
   * @param {number} lat - Latitude
   * @param {number} lng - Longitude
   * @param {number} radius - Raio em km
   * @returns {string} Chave formatada
   */
  generateCacheKey(lat, lng, radius) {
    // Arredonda para 4 casas decimais para agrupar buscas próximas
    const latRounded = parseFloat(lat).toFixed(4);
    const lngRounded = parseFloat(lng).toFixed(4);
    const radiusRounded = parseFloat(radius).toFixed(1);
    
    return `geo:search:lat:${latRounded}:lng:${lngRounded}:radius:${radiusRounded}`;
  }

  /**
   * Obtém dados do cache
   * 
   * @param {string} key - Chave de cache
   * @returns {Promise<Object|null>} Dados em cache ou null
   */
  async get(key) {
    try {
      const data = await redisClient.get(key);
      
      if (data) {
        console.log(`🎯 Cache HIT: ${key}`);
        return JSON.parse(data);
      }
      
      console.log(`❌ Cache MISS: ${key}`);
      return null;
    } catch (error) {
      console.error('❌ Erro ao buscar no Redis:', error);
      return null;
    }
  }

  /**
   * Armazena dados no cache com tempo de expiração
   * 
   * @param {string} key - Chave de cache
   * @param {Object} data - Dados a serem armazenados
   * @param {number} ttl - Tempo de vida em segundos (padrão: 300s = 5min)
   * @returns {Promise<boolean>} Sucesso da operação
   */
  async set(key, data, ttl = 300) {
    try {
      await redisClient.setEx(key, ttl, JSON.stringify(data));
      console.log(`💾 Cache SAVED: ${key} (TTL: ${ttl}s)`);
      return true;
    } catch (error) {
      console.error('❌ Erro ao salvar no Redis:', error);
      return false;
    }
  }

  /**
   * Remove uma chave específica do cache
   * 
   * @param {string} key - Chave a ser removida
   * @returns {Promise<boolean>} Sucesso da operação
   */
  async delete(key) {
    try {
      await redisClient.del(key);
      console.log(`🗑️  Cache DELETED: ${key}`);
      return true;
    } catch (error) {
      console.error('❌ Erro ao deletar do Redis:', error);
      return false;
    }
  }

  /**
   * Limpa todo o cache (usar com cuidado!)
   */
  async flushAll() {
    try {
      await redisClient.flushAll();
      console.log('🧹 Todo cache foi limpo');
      return true;
    } catch (error) {
      console.error('❌ Erro ao limpar cache:', error);
      return false;
    }
  }
}

module.exports = new RedisService();

