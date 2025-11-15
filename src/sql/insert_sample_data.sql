-- ============================================
-- Script de Inserção de Dados de Exemplo
-- ============================================

-- Limpa dados existentes (opcional)
TRUNCATE TABLE psicologos RESTART IDENTITY;

-- ============================================
-- Inserção de Psicólogos em Goiânia/GO
-- ============================================

INSERT INTO psicologos (nome, crp, especialidade, localizacao) VALUES
-- Região Central de Goiânia
('Dr. João Silva', 'CRP 09/12345', 'Psicologia Clínica', ST_SetSRID(ST_MakePoint(-49.2643, -16.6869), 4326)),
('Dra. Marina Santos', 'CRP 09/23456', 'Neuropsicologia', ST_SetSRID(ST_MakePoint(-49.2700, -16.6900), 4326)),
('Dra. Ana Paula Costa', 'CRP 09/34567', 'Psicologia Infantil', ST_SetSRID(ST_MakePoint(-49.2500, -16.6750), 4326)),

-- Região Oeste de Goiânia
('Dr. Carlos Eduardo', 'CRP 09/45678', 'Terapia Cognitiva', ST_SetSRID(ST_MakePoint(-49.3100, -16.6950), 4326)),
('Dra. Fernanda Lima', 'CRP 09/56789', 'Psicologia Organizacional', ST_SetSRID(ST_MakePoint(-49.3200, -16.7000), 4326)),

-- Região Sul de Goiânia
('Dr. Roberto Alves', 'CRP 09/67890', 'Psicoterapia', ST_SetSRID(ST_MakePoint(-49.2550, -16.7200), 4326)),
('Dra. Patricia Moreira', 'CRP 09/78901', 'Psicologia do Esporte', ST_SetSRID(ST_MakePoint(-49.2600, -16.7250), 4326)),

-- Região Norte de Goiânia
('Dr. Lucas Mendes', 'CRP 09/89012', 'Psicologia Social', ST_SetSRID(ST_MakePoint(-49.2400, -16.6500), 4326)),
('Dra. Juliana Rocha', 'CRP 09/90123', 'Avaliação Psicológica', ST_SetSRID(ST_MakePoint(-49.2450, -16.6450), 4326)),

-- Região Leste de Goiânia
('Dr. Marcelo Barbosa', 'CRP 09/01234', 'Psicologia Hospitalar', ST_SetSRID(ST_MakePoint(-49.2200, -16.6800), 4326));

-- ============================================
-- Inserção de Psicólogos em Outras Cidades
-- ============================================

-- Aparecida de Goiânia
INSERT INTO psicologos (nome, crp, especialidade, localizacao) VALUES
('Dra. Camila Freitas', 'CRP 09/11111', 'Terapia Familiar', ST_SetSRID(ST_MakePoint(-49.2443, -16.8232), 4326)),
('Dr. Paulo Henrique', 'CRP 09/22222', 'Psicologia Clínica', ST_SetSRID(ST_MakePoint(-49.2500, -16.8300), 4326));

-- Senador Canedo
INSERT INTO psicologos (nome, crp, especialidade, localizacao) VALUES
('Dra. Rafaela Dias', 'CRP 09/33333', 'Psicopedagogia', ST_SetSRID(ST_MakePoint(-49.0919, -16.7072), 4326));

-- Trindade
INSERT INTO psicologos (nome, crp, especialidade, localizacao) VALUES
('Dr. Thiago Carvalho', 'CRP 09/44444', 'Psicologia Educacional', ST_SetSRID(ST_MakePoint(-49.4889, -16.6489), 4326));

-- Anápolis
INSERT INTO psicologos (nome, crp, especialidade, localizacao) VALUES
('Dra. Beatriz Campos', 'CRP 09/55555', 'Orientação Vocacional', ST_SetSRID(ST_MakePoint(-48.9530, -16.3281), 4326));

-- ============================================
-- Consultas de Validação
-- ============================================

-- Conta total de psicólogos inseridos
SELECT COUNT(*) AS total_psicologos FROM psicologos;

-- Exibe todos os psicólogos com suas coordenadas
SELECT 
    id,
    nome,
    crp,
    especialidade,
    ST_X(localizacao::geometry) AS longitude,
    ST_Y(localizacao::geometry) AS latitude
FROM psicologos
ORDER BY id;

-- Exemplo de consulta geoespacial: Psicólogos em um raio de 5km do centro de Goiânia
-- Centro aproximado: -49.2643, -16.6869
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

