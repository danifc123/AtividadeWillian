const pool = require('../config/database');

/**
 * Serviço responsável pelas operações geoespaciais com PostGIS
 * 
 * PostGIS é uma extensão do PostgreSQL que adiciona suporte para objetos geográficos,
 * permitindo consultas de localização usando SQL.
 */
class PostGISService {
  /**
   * Busca psicólogos próximos a uma coordenada geográfica
   * 
   * @param {number} lat - Latitude do ponto de referência
   * @param {number} lng - Longitude do ponto de referência
   * @param {number} radiusKm - Raio de busca em quilômetros
   * @returns {Promise<Array>} Lista de psicólogos encontrados com suas distâncias
   * 
   * Funções PostGIS utilizadas:
   * - ST_Point: Cria um ponto geográfico a partir de longitude e latitude
   * - ST_DWithin: Filtra pontos dentro de um raio específico (em metros)
   * - ST_Distance: Calcula a distância entre dois pontos geográficos
   * - ::geography: Converte geometria para geografia (cálculos em metros na superfície terrestre)
   */
  async findNearbyPsychologists(lat, lng, radiusKm) {
    const radiusMeters = radiusKm * 1000; // Converte km para metros

    const query = `
      SELECT
        id,
        nome,
        ST_X(localizacao::geometry) AS longitude,
        ST_Y(localizacao::geometry) AS latitude,
        ROUND(
          ST_Distance(
            localizacao::geography,
            ST_SetSRID(ST_Point($1, $2), 4326)::geography
          )::numeric,
          2
        ) AS distancia_metros
      FROM psicologos
      WHERE ST_DWithin(
        localizacao::geography,
        ST_SetSRID(ST_Point($1, $2), 4326)::geography,
        $3
      )
      ORDER BY distancia_metros ASC;
    `;

    try {
      const result = await pool.query(query, [lng, lat, radiusMeters]);
      return result.rows;
    } catch (error) {
      console.error('❌ Erro ao consultar PostGIS:', error);
      throw new Error('Erro ao buscar psicólogos no banco de dados');
    }
  }

  /**
   * Verifica se a extensão PostGIS está instalada
   */
  async checkPostGISExtension() {
    try {
      const result = await pool.query(`
        SELECT EXISTS(
          SELECT 1 FROM pg_extension WHERE extname = 'postgis'
        ) AS postgis_installed;
      `);
      return result.rows[0].postgis_installed;
    } catch (error) {
      console.error('❌ Erro ao verificar extensão PostGIS:', error);
      return false;
    }
  }
}

module.exports = new PostGISService();

