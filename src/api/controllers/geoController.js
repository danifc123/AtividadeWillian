const postgisService = require('../services/postgisService');
const redisService = require('../services/redisService');

/**
 * Controller responsável pelas rotas geoespaciais
 * 
 * Implementa a lógica de cache-aside pattern:
 * 1. Verifica se existe no cache
 * 2. Se existir, retorna do cache
 * 3. Se não existir, consulta o banco
 * 4. Salva no cache para futuras consultas
 * 5. Retorna o resultado
 */
class GeoController {
  /**
   * Busca psicólogos próximos a uma localização
   * 
   * Rota: GET /api/nearby?lat=<lat>&lng=<lng>&radius=<km>
   * 
   * @param {Object} req - Request do Express
   * @param {Object} res - Response do Express
   */
  async findNearby(req, res) {
    const startTime = Date.now();

    try {
      // 1. Extrai e valida parâmetros
      const { lat, lng, radius } = req.query;

      if (!lat || !lng || !radius) {
        return res.status(400).json({
          success: false,
          error: 'Parâmetros obrigatórios: lat, lng, radius',
          example: '/api/nearby?lat=-17.789&lng=-50.123&radius=5',
        });
      }

      const latitude = parseFloat(lat);
      const longitude = parseFloat(lng);
      const radiusKm = parseFloat(radius);

      // Valida valores numéricos
      if (isNaN(latitude) || isNaN(longitude) || isNaN(radiusKm)) {
        return res.status(400).json({
          success: false,
          error: 'Os parâmetros devem ser números válidos',
        });
      }

      // Valida ranges válidos
      if (latitude < -90 || latitude > 90) {
        return res.status(400).json({
          success: false,
          error: 'Latitude deve estar entre -90 e 90',
        });
      }

      if (longitude < -180 || longitude > 180) {
        return res.status(400).json({
          success: false,
          error: 'Longitude deve estar entre -180 e 180',
        });
      }

      if (radiusKm <= 0 || radiusKm > 1000) {
        return res.status(400).json({
          success: false,
          error: 'Radius deve estar entre 0 e 1000 km',
        });
      }

      // 2. Gera chave de cache
      const cacheKey = redisService.generateCacheKey(latitude, longitude, radiusKm);
      console.log(`🔍 Buscando: ${cacheKey}`);

      // 3. Verifica se existe no cache
      const cachedData = await redisService.get(cacheKey);

      if (cachedData) {
        const responseTime = Date.now() - startTime;
        
        return res.json({
          success: true,
          source: 'cache',
          data: cachedData,
          metadata: {
            latitude,
            longitude,
            radius_km: radiusKm,
            count: cachedData.length,
            response_time_ms: responseTime,
          },
        });
      }

      // 4. Consulta no PostGIS
      const psychologists = await postgisService.findNearbyPsychologists(
        latitude,
        longitude,
        radiusKm
      );

      // 5. Salva no cache (TTL: 5 minutos)
      await redisService.set(cacheKey, psychologists, 300);

      // 6. Retorna resultado
      const responseTime = Date.now() - startTime;

      return res.json({
        success: true,
        source: 'database',
        data: psychologists,
        metadata: {
          latitude,
          longitude,
          radius_km: radiusKm,
          count: psychologists.length,
          response_time_ms: responseTime,
        },
      });
    } catch (error) {
      console.error('❌ Erro no controller:', error);
      
      return res.status(500).json({
        success: false,
        error: 'Erro interno no servidor',
        message: error.message,
      });
    }
  }

  /**
   * Endpoint de health check
   */
  async healthCheck(req, res) {
    try {
      const postgisOk = await postgisService.checkPostGISExtension();

      return res.json({
        success: true,
        status: 'running',
        services: {
          postgis: postgisOk ? 'connected' : 'disconnected',
          redis: 'connected',
        },
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        error: 'Health check failed',
        message: error.message,
      });
    }
  }
}

module.exports = new GeoController();

