-- ============================================
-- Script de Criação da Estrutura do Banco
-- ============================================

-- Habilita a extensão PostGIS
-- Esta extensão adiciona suporte para objetos geográficos no PostgreSQL
CREATE EXTENSION IF NOT EXISTS postgis;

-- Verifica se a extensão foi instalada corretamente
SELECT PostGIS_Version();

-- ============================================
-- Tabela de Psicólogos
-- ============================================

-- Remove a tabela se ela já existir (cuidado em produção!)
DROP TABLE IF EXISTS psicologos;

-- Cria a tabela de psicólogos com coluna geoespacial
CREATE TABLE psicologos (
    id SERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    crp TEXT,
    especialidade TEXT,
    localizacao GEOGRAPHY(POINT, 4326) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Comentários explicativos
COMMENT ON TABLE psicologos IS 'Tabela de psicólogos com localização geoespacial';
COMMENT ON COLUMN psicologos.localizacao IS 'Coordenadas geográficas no formato POINT (longitude, latitude) usando SRID 4326 (WGS 84)';

-- ============================================
-- Índices Geoespaciais
-- ============================================

-- Cria índice espacial para otimizar consultas geográficas
-- GIST (Generalized Search Tree) é ideal para dados geoespaciais
CREATE INDEX idx_psicologos_localizacao 
ON psicologos 
USING GIST (localizacao);

-- Índice adicional para busca por nome
CREATE INDEX idx_psicologos_nome 
ON psicologos (nome);

-- ============================================
-- Visualização da Estrutura
-- ============================================

-- Consulta para verificar a estrutura criada
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'psicologos'
ORDER BY ordinal_position;

-- Exibe informações sobre os índices criados
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'psicologos';

