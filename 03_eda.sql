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

-- =========================================================
-- INNER JOIN + FECHA
-- Esta query permite localizar los días de mayor demanda
-- y establecer posibles patrones
-- =========================================================
SELECT
    d.date_id,
    COUNT(*) AS trips_per_day
FROM fact_trips f
INNER JOIN dim_date d
    ON f.date_id = d.date_id
GROUP BY d.date_id
ORDER BY d.date_id;

-- =========================================================
-- LEFT JOIN
-- Esta query detecta estaciones sin uso o poco usadas, para
-- verlo mejor antes meteremos una estación nueva sin viajes
-- y veremos cómo obtenemos 0 viajes en la query
-- =========================================================
INSERT INTO dim_station (station_id, station_name, city, capacity) VALUES
(7,'Test Station','Canarias',15)

SELECT
    s.station_name,
    COUNT(f.trip_id) AS total_trips
FROM dim_station s
LEFT JOIN fact_trips f
    ON s.station_id = f.station_start_id
GROUP BY s.station_name;

-- =========================================================
-- CASE + Condicional
-- Esta query clasifica los viajes por duración permitiendo así
-- segmentar los viajes para tomar decisiones administrativas
-- =========================================================
SELECT
    trip_id,
    duration_minutes,
    CASE
        WHEN duration_minutes < 15 THEN 'Short'
        WHEN duration_minutes BETWEEN 15 AND 30 THEN 'Medium'
        ELSE 'Long'
    END AS trip_type
FROM fact_trips;

-- =========================================================
-- CTES
-- Establecemos un ranking por volumen, de esta manera sabremos
-- cómo priorizar o repartir recursos en las estaciones
-- =========================================================
WITH station_trips AS (
    SELECT
        station_start_id,
        COUNT(*) AS total_trips
    FROM fact_trips
    GROUP BY station_start_id
),
station_rank AS (
    SELECT
        s.station_name,
        st.total_trips,
        RANK() OVER (ORDER BY st.total_trips DESC) AS ranking
    FROM station_trips st
    INNER JOIN dim_station s
        ON st.station_start_id = s.station_id
)
SELECT * FROM station_rank;

-- =========================================================
-- OVER
-- Porcentaje de uso de cada estación
-- =========================================================
SELECT
    s.station_name,
    COUNT(*) AS trips,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_total
FROM fact_trips f
INNER JOIN dim_station s
    ON f.station_start_id = s.station_id
GROUP BY s.station_name;

-- =========================================================
-- VISTA + query
-- Permite analizar rápidamente la carga diaria por estación 
-- sin rehacer JOINs.
-- =========================================================
CREATE VIEW vw_station_daily_summary AS
SELECT
    d.date_id,
    s.station_name,
    COUNT(*) AS total_trips,
    AVG(f.duration_minutes) AS avg_duration
FROM fact_trips f
INNER JOIN dim_date d
    ON f.date_id = d.date_id
INNER JOIN dim_station s
    ON f.station_start_id = s.station_id
GROUP BY d.date_id, s.station_name;

-- La query que nos permite ver la vista resumen anterior
SELECT *
FROM vw_station_daily_summary
WHERE station_name = 'Central Station';

-- =========================================================
-- QUERY FINAL
-- Central Station concentra la mayoría de los viajes y mantiene 
-- una duración media estable, lo que indica que es un punto clave 
-- del sistema y debe priorizarse en mantenimiento y redistribución 
-- de bicicletas.
-- =========================================================
SELECT
    station_name,
    SUM(total_trips) AS trips_total,
    ROUND(AVG(avg_duration),2) AS avg_trip_duration
FROM vw_station_daily_summary
GROUP BY station_name
ORDER BY trips_total DESC;


