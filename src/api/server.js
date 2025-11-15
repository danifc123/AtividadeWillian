const express = require('express');
const dotenv = require('dotenv');
const { connectRedis } = require('./config/redis');
const geoController = require('./controllers/geoController');

// Carrega variáveis de ambiente
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware para parse de JSON
app.use(express.json());

// Middleware de logging
app.use((req, res, next) => {
  console.log(`📡 ${req.method} ${req.path} - ${new Date().toISOString()}`);
  next();
});

/**
 * ROTAS DA API
 */

// Health Check
app.get('/health', geoController.healthCheck.bind(geoController));

// Rota principal: busca psicólogos próximos
app.get('/api/nearby', geoController.findNearby.bind(geoController));

// Rota de documentação (root)
app.get('/', (req, res) => {
  res.json({
    project: 'Geospatial + Key-Value Database Integration',
    description: 'API demonstrando uso de PostGIS e Redis',
    version: '1.0.0',
    endpoints: {
      nearby: {
        method: 'GET',
        path: '/api/nearby',
        params: {
          lat: 'Latitude (number, -90 to 90)',
          lng: 'Longitude (number, -180 to 180)',
          radius: 'Raio em km (number, 0 to 1000)',
        },
        example: '/api/nearby?lat=-17.789&lng=-50.123&radius=5',
      },
      health: {
        method: 'GET',
        path: '/health',
        description: 'Verifica status dos serviços',
      },
    },
    technologies: {
      database: 'PostgreSQL + PostGIS (Geospatial)',
      cache: 'Redis (Key-Value)',
      framework: 'Express.js',
    },
  });
});

// Rota 404
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Rota não encontrada',
    available_routes: ['/', '/health', '/api/nearby'],
  });
});

/**
 * INICIALIZAÇÃO DO SERVIDOR
 */
async function startServer() {
  try {
    // Conecta ao Redis
    await connectRedis();

    // Inicia o servidor
    app.listen(PORT, () => {
      console.log('');
      console.log('🚀 ========================================');
      console.log('🚀  Servidor rodando com sucesso!');
      console.log('🚀 ========================================');
      console.log(`📍  URL: http://localhost:${PORT}`);
      console.log(`📍  Health: http://localhost:${PORT}/health`);
      console.log(`📍  API: http://localhost:${PORT}/api/nearby`);
      console.log('🚀 ========================================');
      console.log('');
    });
  } catch (error) {
    console.error('❌ Falha ao iniciar servidor:', error);
    process.exit(1);
  }
}

// Tratamento de erros não capturados
process.on('unhandledRejection', (error) => {
  console.error('❌ Unhandled Rejection:', error);
  process.exit(1);
});

// Inicia o servidor
startServer();

