# HR Analytics dbt Project

## Overview
End-to-end HR Analytics data pipeline built on Snowflake using dbt.
Implements Medallion Architecture (Bronze → Silver → Gold) with
a Kimball-style Star Schema in the Gold layer.

## Architecture
S3 → COPY INTO → Staging → Bronze (dbt view) → Silver (dbt table) → Gold (Star Schema)

## Tech Stack
- Snowflake — data warehouse
- dbt — transformations and testing
- AWS S3 — raw file storage
- Python — data generation

## Layers
- **Bronze** — raw view on staging, no transformations
- **Silver** — cleaned, typed, validated with seed joins and quarantine
- **Gold** — Kimball star schema with fact and dimension tables

## Models
- `bronze_hr_data_raw` — view on staging table
- `silver_hr_cleaned` — 200 employees, fully cleaned and validated
- `silver_hr_quarantine` — rejected rows with failure reason
- `dim_employee`, `dim_manager`, `dim_job_role`, `dim_org`, `dim_location`, `dim_date`
- `fact_employee_snapshot` — grain: one row per employee per snapshot

## Tests
- 121 generic tests on silver — not_null, accepted_values, relationships
- 2 singular tests — manager hierarchy rules with warn severity

## Key Design Decisions
- Kimball 4-step methodology for dimensional design
- Quarantine pattern for bad data visibility
- Seed tables as allowed-value validators via INNER JOIN
- DIM_DATE using YYYYMMDD integer surrogate key
- SCD2 on DIM_EMPLOYEE for historical tracking