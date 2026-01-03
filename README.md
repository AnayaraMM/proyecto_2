# Bike Sharing SQL Project

## 📌 Descripción del proyecto

Este repositorio contiene un proyecto académico de **Diseño de Base de Datos Relacional y Análisis Exploratorio en SQL**, basado en un sistema ficticio de **bike sharing**.
---

## 🧱 Estructura del modelo

El modelo sigue un **esquema en estrella**, compuesto por:

- **Tabla de hechos**
  - `fact_trips`: registra los viajes realizados (evento principal).

- **Tablas de dimensiones**
  - `dim_date`: dimensión temporal.
  - `dim_station`: información de estaciones.
  - `dim_user_type`: tipo de usuario.
  - `dim_time_slot`: franjas horarias.

Este diseño facilita análisis agregados, JOINs eficientes y escalabilidad del modelo.

---

## 📊 Dataset

⚠️ **Importante – Origen de los datos**

El dataset utilizado en este proyecto **no procede de un sistema real ni de una fuente pública**.

👉 **Los datos han sido generados de forma sintética con ayuda de ChatGPT**, con fines exclusivamente educativos
---

## 🛠️ Tecnologías utilizadas

- **PostgreSQL**
- SQL estándar (CREATE, INSERT, UPDATE, DELETE, JOIN, CTEs, Views, funciones ventana)
- Dataset sintético generado con **ChatGPT**

---
