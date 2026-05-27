# HR Analytics dbt Project

**GitHub:** https://github.com/epvidya/Hr_Analytics_dbt_Project
**Tableau:** https://public.tableau.com/app/profile/vidya.egambaram.paramasivam/vizzes

## Overview

End-to-end HR Analytics data pipeline built on Snowflake using dbt. Implements Medallion Architecture (Bronze to Silver to Gold) with a Kimball-style Star Schema in the Gold layer. Covers raw data ingestion from AWS S3 through transformation and validation to dimensional modelling — backed by 121 automated data quality tests, 11 business analytics queries, Streamlit dashboard and Tableau visualisations. Pipeline supports multi-snapshot monthly data with incremental processing via Streams, Tasks and Dynamic Tables.

## Architecture

```
S3 → COPY INTO → Staging → Bronze (dbt view) → Silver (dbt table) → Gold (Star Schema)
                               ↓ Stream detects new rows
                               ↓ Task triggers processing
                               ↓ Dynamic Table auto-refreshes aggregates
```

## Tech Stack

- **Snowflake** — data warehouse (COPY INTO, Streams, Tasks, Dynamic Tables, Snowpipe, Time Travel, Zero-Copy Cloning)
- **dbt** — transformations, testing, documentation, seed management, dbt_utils, incremental materialisation
- **AWS S3** — raw file storage with storage integration and file format management
- **Tableau** — 2 HR analytics dashboards (People Story + Compensation Story) published to Tableau Public
- **Python** — pandas for synthetic data generation, Streamlit in Snowflake for interactive dashboards
- **Git / GitHub** — version control with documented commit history

## Layers

### Bronze
Raw view on top of staging table. All 52 columns remain VARCHAR — no transformations. Not_null and unique tests on critical columns. Constant columns (employee_count, over_18, standard_hours) dropped in silver.

### Silver
- `silver_hr_cleaned` — fully cleaned and validated. TRY_CAST, TRY_TO_DATE, INITCAP, TRIM, CASE for business_travel dirty values. 10 seed tables as allowed-value validators via INNER JOIN. LEFT JOIN for termination_reason on active employees. Incremental materialisation — only processes rows where _load_timestamp exceeds existing max.
- `silver_hr_quarantine` — Rejected rows captured with ARRAY_CONSTRUCT_COMPACT failure_reason column.
- 121 dbt generic tests — not_null, accepted_values, relationships, unique_combination_of_columns(emp_id + snapshot_date)
- 2 singular tests — manager hierarchy business rules with severity: warn

### Gold — Dimensions
- `dim_date` — 7,670 rows. Recursive CTE covering calendar year, fiscal year (April start), ISO week numbers and US day-of-week mapping. SK is YYYYMMDD integer.
- `dim_employee` — SCD2 ready with valid_from, valid_to, is_current columns for historical tracking.
- `dim_manager` — Self join on silver_hr_cleaned. Only employees who appear as manager_id.
- `dim_job_role` — DISTINCT job_role + job_level combinations.
- `dim_org` — DISTINCT department + business_travel combinations.
- `dim_location` — 11 cities with state, region and cost_center from seed_location.

### Gold — Fact
- `fact_employee_snapshot` — Grain: one row per employee per snapshot date. dim_date role-playing dimension joined four times — snapshot_date_sk, join_date_sk, exit_date_sk, last_promotion_date_sk. SKs pulled from dims via natural key joins.

### Gold — Dynamic Table
- `dt_attrition_summary` — Pre-aggregated attrition metrics by department and snapshot month. TARGET_LAG = 1 hour. Auto-refreshes when fact_employee_snapshot changes. Queried by Streamlit dashboard for fast KPI display.

## Snowflake Advanced Features

- **Stream** — `hr_data_raw_stream` on staging table (APPEND_ONLY). Detects new rows on each monthly CSV load.
- **Task** — `process_new_snapshots` fires when stream has data. Logs trigger events with timestamp and row count.
- **Dynamic Table** — `dt_attrition_summary` auto-refreshes attrition aggregates within 1 hour of upstream changes.
- **Incremental materialisation** — `silver_hr_cleaned` processes only new rows based on _load_timestamp — avoids full rebuilds on each monthly load.

## Seeds

10 reference tables loaded via `dbt seed`. Each acts as an allowed-value validator in silver via INNER JOIN.

- `seed_education_level` — education codes 1-5 decoded to label
- `seed_rating_scale` — shared 1-4 scale joined 6 times for all survey columns
- `seed_job_level` — job level 1-5 decoded to Junior through Principal
- `seed_salary_slab` — salary band definitions with min and max income ranges
- `seed_stock_option_level` — stock option 0-3 decoded to None through High
- `seed_business_travel` — validates standardised travel values after CASE cleaning
- `seed_employment_type` — Full Time, Part Time, Contract with is_full_time flag for FTE headcount
- `seed_recruitment_source` — 5 channels with category and cost for effectiveness analysis
- `seed_termination_reason` — 5 reasons with is_voluntary flag for attrition type split
- `seed_location` — 11 cities mapped to department, state, region and cost_center

## Tests

- **121 generic tests** on silver — not_null, accepted_values, relationships to all seeds
- **unique_combination_of_columns(emp_id, snapshot_date)** — validates grain in silver
- **Gold tests** — surrogate key uniqueness, date_sk relationships to dim_date, manager_id relationship to dim_employee
- **2 singular tests** — manager hierarchy rules with severity: warn so violations surface without blocking pipeline

## Analyses

11 SQL queries in the `analyses/` folder. Compile with `dbt compile --select <filename>` then run in Snowflake. All queries include snapshot_date_sk and month_year for Tableau time-series visualisation.

- `attrition_rate.sql` — Attrition rate and voluntary vs involuntary split by department, job level and snapshot month
- `headcount_trend.sql` — Headcount trends with FTE vs non-FTE and overtime breakdown by department and region
- `compensation_distribution.sql` — Salary band distribution, band compliance and non-compliance rate by department and job level
- `tenure_analysis.sql` — Individual employee tenure with tenure_band for Tableau grouping — satisfaction and attrition by tenure
- `dept_satisfaction_trend.sql` — Average job satisfaction by department and snapshot month
- `top_employee_satisfaction.sql` — Employee with highest job satisfaction per month using DENSE_RANK and QUALIFY
- `high_performer_attrition.sql` — High performers (rating >= 3) who already left — post mortem by termination reason
- `high_performer_dissatisfied.sql` — High performers still employed with low satisfaction — proactive retention list
- `high_performer_flight_risk.sql` — Flight risk scoring model — 6 factors, Critical/High/Medium/Low classification
- `promotion_overdue_active.sql` — Active employees not promoted in 3+ years — HR intervention list
- `promotion_overdue_attrited.sql` — Employees who left after 3+ years without promotion — post mortem

## Streamlit Dashboard

Multi-page Streamlit in Snowflake app querying gold layer directly:
- Page 1 — Attrition split by category with dynamic snapshot date selector, KPI cards and bar chart
- Page 2 — Attrition by department and category with pivot-based grouped bar chart
- Queries `dt_attrition_summary` Dynamic Table for fast pre-aggregated results

## Tableau Dashboards

Two dashboards published to Tableau Public — [view here](https://public.tableau.com/app/profile/vidya.egambaram.paramasivam/vizzes)

- **Dashboard 1: People Story** — Attrition rate by department (bar chart, months sorted chronologically) + satisfaction trend by department with headcount in tooltip
- **Dashboard 2: Compensation Story** — Salary distribution by band and job level + average salary by role and level + pay equity analysis with department and month filters

## Key Design Decisions

- **Kimball 4-step methodology** — business process, grain, dimensions, facts
- **Surrogate keys** — dbt_utils.generate_surrogate_key() MD5 hash — stable and deterministic regardless of rebuild order
- **DIM_DATE YYYYMMDD integer SK** — self-documenting and enables date range queries without joining
- **Role-playing dimension** — dim_date joined four times in fact for snapshot, join, exit and promotion dates
- **Quarantine pattern** — bad data captured with failure_reason, not silently dropped
- **Seed INNER JOIN validation** — seeds act as allowed-value filters, invalid rows go to quarantine
- **SCD2 on DIM_EMPLOYEE** — valid_from, valid_to, is_current for historical tracking
- **LEFT JOIN for termination_reason** — active employees pass through with NULL labels
- **severity: warn on singular tests** — violations surface without blocking pipeline
- **No inline SQL comments** — all documentation in dbt yaml properties files
- **Fact pulls SKs from dims** — natural key joins, no MD5 recalculation in fact
- **is_incremental on silver** — only new rows processed on each monthly load
- **Dynamic Table for aggregates** — pre-computed metrics refreshed automatically, fast dashboard queries
- **unique_combination_of_columns** — grain test on silver after multi-snapshot support added

## Project Structure

```
hr_analytics/
├── models/
│   ├── staging/sources.yml
│   ├── bronze/
│   ├── silver/
│   └── gold/
│       ├── dimensions/
│       └── facts/
├── seeds/
├── tests/
├── analyses/
├── streamlit/
├── macros/
├── packages.yml
└── dbt_project.yml
```

## How to Run

- `dbt deps` — install dbt_utils package
- `dbt seed` — load all 10 reference tables into seeds schema
- `dbt build` — build all models and run all tests in dependency order
- `dbt compile --select attrition_rate` — compile analysis SQL for Snowflake
- New monthly CSV — COPY INTO staging, then `dbt build --select silver_hr_cleaned+`