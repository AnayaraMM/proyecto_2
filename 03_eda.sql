-- =========================================================
-- FUNCIONES DE FECHA (SQLite)
-- Extraemos año y mes desde date_id (formato DD/MM/YYYY)
-- =========================================================
SELECT
    date_id,
    SUBSTRING(TO_CHAR(date_id, 'YYYY-MM-DD') FROM 1 FOR 4) AS year,
    SUBSTRING(TO_CHAR(date_id, 'YYYY-MM-DD') FROM 6 FOR 2) AS month
FROM dim_date;

-- =========================================================
-- AGREGACIONES (COUNT, SUM)
-- Número de viajes y duración total por estación de inicio
-- =========================================================
SELECT
    station_start_id,
    COUNT(*) AS total_trips,
    SUM(duration_minutes) AS total_minutes
FROM fact_trips
GROUP BY station_start_id;

-- =========================================================
-- SUBQUERY
-- Estaciones con más viajes que la media
-- =========================================================
SELECT
    station_start_id,
    COUNT(*) AS trips
FROM fact_trips
GROUP BY station_start_id
HAVING COUNT(*) >
    (
        SELECT AVG(trip_count)
        FROM (
            SELECT COUNT(*) AS trip_count
            FROM fact_trips
            GROUP BY station_start_id
        )
    );