-- =========================================================
-- LIMPIEZA PREVIA (para ejecución desde cero)
-- =========================================================
DROP TABLE IF EXISTS fact_trips;
DROP TABLE IF EXISTS dim_time_slot;
DROP TABLE IF EXISTS dim_user_type;
DROP TABLE IF EXISTS dim_station;
DROP TABLE IF EXISTS dim_date;


BEGIN;
-- =========================================================
-- DIM_DATE
-- Granularidad -> cada fila representa un día concreto (date_id)
-- Dentro/fuera del alcance:
	-- Dentro: permite analizar viajes por día, semana, mes o año.
	-- Fuera: no incluye información de hora exacta de cada viaje; 
	-- para eso usamos la tabla dim_time_slot.
-- Decisiones de PK, FK y constraints:
	-- date_id es la PK, porque cada fecha es única.
	-- Constraints NOT NULL y CHECK en day, month y year garantizan valores válidos.
	-- FK en fact_trips (date_id) referencia esta tabla para mantener integridad.
-- Se separa la información temporal para evitar repetir día, mes y año en cada viaje. 
-- Facilita los análisis por fecha y mantiene consistencia en los datos temporales.
-- =========================================================
CREATE TABLE IF NOT EXISTS dim_date (
    date_id DATE PRIMARY KEY,
    day INTEGER NOT NULL CHECK (day BETWEEN 1 AND 31),
    month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
    year INTEGER NOT NULL CHECK (year >= 2000)
);

-- =========================================================
-- DIM_STATION
-- Granularidad -> cada fila representa una estación
-- Dentro/fuera del alcance:
	-- Dentro: análisis por estación de inicio o fin de viaje, capacidad y ubicación.
	-- Fuera: no incluye coordenadas exactas ni información histórica de estaciones.
-- Decisiones de PK, FK y constraints:
	-- station_id es la PK, autoincremental (SERIAL) para identificar unívocamente cada estación.
	-- Constraints NOT NULL y CHECK(capacity > 0) para evitar valores inválidos.
	-- station_start_id y station_end_id en fact_trips son FK a esta tabla.
-- La información de las estaciones se almacena en una tabla independiente para no duplicar nombres,
-- ciudades y capacidades en cada viaje. Permite actualizar datos de una estación en un único lugar.
-- =========================================================
CREATE TABLE IF NOT EXISTS dim_station (
    station_id SERIAL PRIMARY KEY,
    station_name TEXT NOT NULL UNIQUE,
    city TEXT NOT NULL,
    capacity INTEGER NOT NULL CHECK (capacity > 0)
);

-- =========================================================
-- DIM_USER_TYPE
-- Granularidad -> cada fila representa un tipo de usuario
-- Dentro/fuera del alcance:
	-- Dentro: permite segmentar viajes según el tipo de usuario.
	-- Fuera: no incluye información personal de usuarios (nombre, edad, etc.).
-- Decisiones de PK, FK y constraints:
	-- user_type_id es la PK autoincremental.
	-- Constraint UNIQUE en user_type asegura que no haya duplicados.
	-- FK en fact_trips (user_type_id) mantiene integridad y relación con viajes.
-- Se normalizan los tipos de usuario para evitar repetir etiquetas como “Subscriber” o “Casual” 
-- en la tabla de hechos y garantizar valores únicos y controlados.
-- =========================================================
CREATE TABLE IF NOT EXISTS dim_user_type (
    user_type_id SERIAL PRIMARY KEY,
    user_type TEXT NOT NULL UNIQUE
);

-- =========================================================
-- DIM_TIME_SLOT
-- Granularidad -> cada fila representa una franja horaria
-- Dentro/fuera del alcance:
	-- Dentro: permite agrupar viajes según franjas horarias y hacer análisis temporal más detallado.
	-- Fuera: no representa la hora exacta de inicio de cada viaje (solo la franja).
-- Decisiones de PK, FK y constraints:
	-- time_slot_id es la PK autoincremental.
	-- Constraints NOT NULL y CHECK(start_hour BETWEEN 0 AND 23) garantizan valores correctos.
	-- FK en fact_trips (time_slot_id) mantiene integridad.
-- Las franjas horarias se separan para estandarizar los rangos de horas y evitar inconsistencias
-- en su definición. Facilita análisis por bloques temporales.
-- =========================================================
CREATE TABLE IF NOT EXISTS dim_time_slot (
    time_slot_id SERIAL PRIMARY KEY,
    slot_name TEXT NOT NULL UNIQUE,
    start_hour INTEGER NOT NULL CHECK (start_hour BETWEEN 0 AND 23),
    end_hour INTEGER NOT NULL CHECK (end_hour BETWEEN 0 AND 23)
);

-- =========================================================
-- FACT_TRIPS
-- Tabla de hechos
-- Granularidad -> 1 fila = 1 viaje
-- Dentro/fuera del alcance:
	-- Dentro: permite análisis de número de viajes, duración promedio, 
	-- ranking de estaciones, franjas horarias y tipos de usuario.
	-- Fuera: no incluye datos personales de usuarios ni información de bicicletas individuales.
-- Decisiones de PK, FK y constraints:
	-- trip_id es la PK autoincremental para identificar cada viaje.
	-- FKs: date_id, station_start_id, station_end_id, user_type_id, time_slot_id garantizan integridad y normalización.
	-- Constraint duration_minutes > 0 asegura que los viajes tengan una duración válida.
-- Contiene solo los hechos del negocio (viajes) y referencias a las dimensiones mediante claves foráneas. 
-- Esto reduce redundancia, mejora la integridad de los datos y permite análisis flexibles mediante JOINs.
-- =========================================================
CREATE TABLE IF NOT EXISTS fact_trips (
    trip_id SERIAL PRIMARY KEY,
    date_id DATE NOT NULL,
    station_start_id INTEGER NOT NULL,
    station_end_id INTEGER NOT NULL,
    user_type_id INTEGER NOT NULL,
    time_slot_id INTEGER NOT NULL,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),

    CONSTRAINT fk_date FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    CONSTRAINT fk_station_start FOREIGN KEY (station_start_id) REFERENCES dim_station(station_id),
    CONSTRAINT fk_station_end FOREIGN KEY (station_end_id) REFERENCES dim_station(station_id),
    CONSTRAINT fk_user_type FOREIGN KEY (user_type_id) REFERENCES dim_user_type(user_type_id),
    CONSTRAINT fk_time_slot FOREIGN KEY (time_slot_id) REFERENCES dim_time_slot(time_slot_id)
);

COMMIT;

-- =========================================================
-- ÍNDICE
-- Mejora el rendimiento de análisis por fecha aunque ralentiza 
-- las inserciones
-- =========================================================
CREATE INDEX IF NOT EXISTS idx_fact_trips_date
ON fact_trips(date_id);

-- =========================================================
-- INSERT
-- =========================================================
INSERT INTO dim_user_type (user_type_id, user_type)
VALUES (3, 'Tourist');

-- =========================================================
-- UPDATE
-- =========================================================
UPDATE dim_station
SET capacity = capacity + 5
WHERE city = 'Helsinki';

-- =========================================================
-- DELETE
-- =========================================================
DELETE FROM dim_user_type
WHERE user_type = 'Tourist';

-- =========================================================
-- CAST
-- Convertimos duración a entero para cálculos
-- =========================================================
SELECT
    trip_id,
    CAST(duration_minutes AS INTEGER) AS duration_int
FROM fact_trips;

