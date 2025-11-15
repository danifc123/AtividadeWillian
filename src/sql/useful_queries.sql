-- ============================================
-- QUERIES ÚTEIS PARA DESENVOLVIMENTO E TESTES
-- ============================================

-- ============================================
-- 1. CONSULTAS BÁSICAS
-- ============================================

-- Ver todos os psicólogos com suas coordenadas
SELECT 
    id,
    nome,
    crp,
    especialidade,
    ST_X(localizacao::geometry) AS longitude,
    ST_Y(localizacao::geometry) AS latitude,
    ST_AsText(localizacao) AS localizacao_wkt
FROM psicologos
ORDER BY id;

-- Contar total de psicólogos
SELECT COUNT(*) AS total_psicologos FROM psicologos;

-- Listar especialidades únicas
SELECT DISTINCT especialidade, COUNT(*) as quantidade
FROM psicologos
GROUP BY especialidade
ORDER BY quantidade DESC;

-- ============================================
-- 2. CONSULTAS GEOESPACIAIS BÁSICAS
-- ============================================

-- Psicólogos em um raio de 5km do centro de Goiânia
SELECT 
    id,
    nome,
    especialidade,
    ROUND(
        ST_Distance(
            localizacao::geography,
            ST_SetSRID(ST_MakePoint(-49.2643, -16.6869), 4326)::geography
        )::numeric,
        2
    ) AS distancia_metros
FROM psicologos
WHERE ST_DWithin(
    localizacao::geography,
    ST_SetSRID(ST_MakePoint(-49.2643, -16.6869), 4326)::geography,
    5000  -- 5km em metros
)
ORDER BY distancia_metros ASC;

-- Encontrar os 5 psicólogos mais próximos de um ponto
SELECT 
    id,
    nome,
    especialidade,
    ROUND(
        ST_Distance(
            localizacao::geography,
            ST_SetSRID(ST_MakePoint(-49.2643, -16.6869), 4326)::geography
        )::numeric,
        2
    ) AS distancia_metros
FROM psicologos
ORDER BY localizacao::geography <-> ST_SetSRID(ST_MakePoint(-49.2643, -16.6869), 4326)::geography
LIMIT 5;

-- ============================================
-- 3. ANÁLISES GEOESPACIAIS AVANÇADAS
-- ============================================

-- Distância entre todos os pares de psicólogos
SELECT 
    p1.nome AS psicologo_1,
    p2.nome AS psicologo_2,
    ROUND(
        ST_Distance(
            p1.localizacao::geography,
            p2.localizacao::geography
        )::numeric,
        2
    ) AS distancia_metros
FROM psicologos p1
CROSS JOIN psicologos p2
WHERE p1.id < p2.id
ORDER BY distancia_metros ASC
LIMIT 10;

-- Criar um buffer (área circular) de 2km ao redor de cada psicólogo
-- e contar quantos outros psicólogos estão nessa área
SELECT 
    p1.nome,
    p1.especialidade,
    COUNT(p2.id) - 1 AS psicologos_proximos
FROM psicologos p1
LEFT JOIN psicologos p2 ON ST_DWithin(
    p1.localizacao::geography,
    p2.localizacao::geography,
    2000  -- 2km
)
GROUP BY p1.id, p1.nome, p1.especialidade
ORDER BY psicologos_proximos DESC;

-- Encontrar o ponto central (centróide) de todos os psicólogos
SELECT 
    ST_AsText(ST_Centroid(ST_Collect(localizacao::geometry))) AS centroide,
    ST_X(ST_Centroid(ST_Collect(localizacao::geometry))) AS longitude_central,
    ST_Y(ST_Centroid(ST_Collect(localizacao::geometry))) AS latitude_central
FROM psicologos;

-- ============================================
-- 4. CONSULTAS POR REGIÃO
-- ============================================

-- Psicólogos em Goiânia (aproximadamente)
-- Bounding box: lat entre -16.60 e -16.75, lng entre -49.35 e -49.20
SELECT 
    id,
    nome,
    especialidade,
    ST_X(localizacao::geometry) AS longitude,
    ST_Y(localizacao::geometry) AS latitude
FROM psicologos
WHERE 
    ST_X(localizacao::geometry) BETWEEN -49.35 AND -49.20
    AND ST_Y(localizacao::geometry) BETWEEN -16.75 AND -16.60
ORDER BY nome;

-- Psicólogos agrupados por proximidade (clusters simples)
-- Agrupa por região arredondando coordenadas
SELECT 
    ROUND(ST_X(localizacao::geometry)::numeric, 2) AS lng_region,
    ROUND(ST_Y(localizacao::geometry)::numeric, 2) AS lat_region,
    COUNT(*) AS quantidade,
    STRING_AGG(nome, ', ') AS psicologos
FROM psicologos
GROUP BY lng_region, lat_region
ORDER BY quantidade DESC;

-- ============================================
-- 5. VALIDAÇÃO E QUALIDADE DOS DADOS
-- ============================================

-- Verificar se todas as geometrias são válidas
SELECT 
    id,
    nome,
    ST_IsValid(localizacao::geometry) AS geometria_valida,
    CASE 
        WHEN ST_IsValid(localizacao::geometry) THEN 'OK'
        ELSE ST_IsValidReason(localizacao::geometry)
    END AS razao
FROM psicologos;

-- Verificar o SRID (Sistema de Referência Espacial)
SELECT 
    id,
    nome,
    ST_SRID(localizacao::geometry) AS srid
FROM psicologos;

-- Verificar tipo de geometria
SELECT 
    id,
    nome,
    GeometryType(localizacao::geometry) AS tipo_geometria
FROM psicologos;

-- ============================================
-- 6. PERFORMANCE E ÍNDICES
-- ============================================

-- Ver informações sobre os índices espaciais
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'psicologos';

-- Analisar uso do índice espacial
EXPLAIN ANALYZE
SELECT id, nome
FROM psicologos
WHERE ST_DWithin(
    localizacao::geography,
    ST_SetSRID(ST_MakePoint(-49.2643, -16.6869), 4326)::geography,
    5000
);

-- Estatísticas da tabela
SELECT 
    schemaname,
    tablename,
    n_live_tup AS linhas_ativas,
    n_dead_tup AS linhas_mortas,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE tablename = 'psicologos';

-- ============================================
-- 7. MANUTENÇÃO E ADMINISTRAÇÃO
-- ============================================

-- Recriar o índice espacial (se necessário)
DROP INDEX IF EXISTS idx_psicologos_localizacao;
CREATE INDEX idx_psicologos_localizacao 
ON psicologos 
USING GIST (localizacao);

-- Atualizar estatísticas da tabela
ANALYZE psicologos;

-- Vacuum completo (libera espaço)
VACUUM FULL psicologos;

-- Ver tamanho da tabela e índices
SELECT
    pg_size_pretty(pg_total_relation_size('psicologos')) AS tamanho_total,
    pg_size_pretty(pg_relation_size('psicologos')) AS tamanho_tabela,
    pg_size_pretty(pg_indexes_size('psicologos')) AS tamanho_indices;

-- ============================================
-- 8. INSERÇÃO E ATUALIZAÇÃO
-- ============================================

-- Inserir novo psicólogo
INSERT INTO psicologos (nome, crp, especialidade, localizacao)
VALUES (
    'Dr. Teste',
    'CRP 09/99999',
    'Teste',
    ST_SetSRID(ST_MakePoint(-49.2643, -16.6869), 4326)
);

-- Atualizar localização de um psicólogo
UPDATE psicologos
SET localizacao = ST_SetSRID(ST_MakePoint(-49.2700, -16.6900), 4326)
WHERE id = 1;

-- Deletar psicólogo
DELETE FROM psicologos WHERE id = 99;

-- ============================================
-- 9. CONVERSÕES DE FORMATO
-- ============================================

-- Converter para diferentes formatos de geometria
SELECT 
    id,
    nome,
    ST_AsText(localizacao) AS wkt,
    ST_AsEWKT(localizacao) AS ewkt,
    ST_AsGeoJSON(localizacao) AS geojson,
    ST_AsKML(localizacao) AS kml
FROM psicologos
LIMIT 3;

-- ============================================
-- 10. QUERIES ÚTEIS PARA DEBUG
-- ============================================

-- Ver todas as extensões PostGIS instaladas
SELECT * FROM pg_available_extensions WHERE name LIKE 'postgis%';

-- Ver versão do PostGIS
SELECT PostGIS_Version();
SELECT PostGIS_Full_Version();

-- Ver funções PostGIS disponíveis
SELECT 
    proname AS nome_funcao,
    pg_get_function_identity_arguments(p.oid) AS argumentos
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
    AND proname LIKE 'st_%'
ORDER BY proname
LIMIT 20;

-- Ver tabelas com colunas geoespaciais
SELECT 
    f_table_schema,
    f_table_name,
    f_geometry_column,
    coord_dimension,
    srid,
    type
FROM geometry_columns;

-- ============================================
-- 11. BENCHMARK E COMPARAÇÃO
-- ============================================

-- Comparar performance: com índice vs sem índice
-- (Execute com \timing on no psql)

-- Com índice (rápido)
SELECT COUNT(*) 
FROM psicologos
WHERE ST_DWithin(
    localizacao::geography,
    ST_SetSRID(ST_MakePoint(-49.2643, -16.6869), 4326)::geography,
    5000
);

-- Medir tempo de resposta médio
SELECT 
    AVG(query_time) AS tempo_medio_ms
FROM (
    SELECT 
        extract(milliseconds from (clock_timestamp() - statement_timestamp())) AS query_time
    FROM psicologos
    WHERE ST_DWithin(
        localizacao::geography,
        ST_SetSRID(ST_MakePoint(-49.2643, -16.6869), 4326)::geography,
        5000
    )
) t;

-- ============================================
-- FIM
-- ============================================

