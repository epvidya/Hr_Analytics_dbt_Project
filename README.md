# HR Analytics dbt Project

**GitHub:** https://github.com/epvidya/Hr_Analytics_dbt_Project

## Overview

End-to-end HR Analytics data pipeline built on Snowflake using dbt. Implements Medallion Architecture (Bronze to Silver to Gold) with a Kimball-style Star Schema in the Gold layer. Covers raw data ingestion from AWS S3 through transformation and validation to dimensional modelling — backed by 121 automated data quality tests and 10 business analytics queries.

## Architecture

```
S3 → COPY INTO → Staging → Bronze (dbt view) → Silver (dbt table) → Gold (Star Schema)
```

## Tech Stack

- **Snowflake** — data warehouse (COPY INTO, storage integration, compute warehouse)
- **dbt** — transformations, testing, documentation, seed management, dbt_utils package
- **AWS S3** — raw file storage with storage integration and file format management
- **Python** — pandas for data generation, Streamlit for visualisation
- **Git / GitHub** — version control with documented commit history

## Layers

### Bronze
Raw view on top of staging table. All 52 columns remain VARCHAR — no transformations. Not_null and unique tests on critical columns. Constant columns (employee_count, over_18, standard_hours) dropped in silver.

### Silver
- `silver_hr_cleaned` — 200 employees fully cleaned and validated. TRY_CAST, TRY_TO_DATE, INITCAP, TRIM, CASE statement for business_travel dirty values. 10 seed tables as allowed-value validators via INNER JOIN. LEFT JOIN for termination_reason on active employees.
- `silver_hr_quarantine` — Rejected rows captured with ARRAY_CONSTRUCT_COMPACT failure_reason column. Shows which validation failed and what the raw value was.
- 121 dbt generic tests — not_null, accepted_values, relationships to all seeds
- 2 singular tests — manager hierarchy business rules with severity: warn

### Gold — Dimensions
- `dim_date` — 7,670 rows. Recursive CTE covering calendar year, fiscal year (April start), ISO week numbers and US day-of-week mapping. SK is YYYYMMDD integer — self-documenting and enables range queries without joining.
- `dim_employee` — 200 rows. SCD2 ready with valid_from, valid_to, is_current columns for historical tracking.
- `dim_manager` — ~30 rows. Self join on silver_hr_cleaned. Only employees who appear as manager_id are included.
- `dim_job_role` — ~26 rows. DISTINCT job_role + job_level combinations. Natural key is both columns together.
- `dim_org` — ~9 rows. DISTINCT department + business_travel combinations.
- `dim_location` — 11 rows. Cities with state, region and cost_center from seed_location.

### Gold — Fact
- `fact_employee_snapshot` — 200 rows. Grain: one row per employee per snapshot date. dim_date is a role-playing dimension joined four times — snapshot_date_sk, join_date_sk, exit_date_sk, last_promotion_date_sk. SKs pulled from dims via natural key joins — no MD5 recalculation in fact.

## Seeds

10 reference tables loaded via `dbt seed`. Each acts as an allowed-value validator in silver via INNER JOIN — invalid rows go to quarantine with a failure reason.

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
- **Gold tests** — surrogate key uniqueness, date_sk relationships to dim_date, manager_id relationship to dim_employee
- **2 singular tests** — manager hierarchy rules with severity: warn so violations surface without blocking pipeline

## Analyses

10 SQL queries in the `analyses/` folder. Compile with `dbt compile --select <filename>` then run compiled SQL in Snowflake.

- `attrition_rate.sql` — Attrition rate and voluntary vs involuntary split by department, job level and recruitment source
- `headcount_trend.sql` — Headcount trends with FTE vs non-FTE and overtime breakdown by department and region
- `compensation_distribution.sql` — Salary band distribution and band compliance rate by department and job level
- `tenure_analysis.sql` — Tenure bands, satisfaction by tenure group and attrition rate by tenure
- `promotion_cycle_analysis.sql` — Promotion cycle using DATEDIFF on actual dates and overdue promotion detection
- `dept_satisfaction_trend.sql` — Department satisfaction ranking using RANK window function partitioned by month
- `top_employee_satisfaction.sql` — Employee with highest job satisfaction per month using DENSE_RANK and QUALIFY
- `high_performer_attrition.sql` — High performers who already left — post mortem by termination reason and tenure
- `high_performer_dissatisfied.sql` — High performers still employed with low satisfaction — early warning list
- `high_performer_flight_risk.sql` — Flight risk scoring model with 6 factors and Critical/High/Medium/Low classification

## Key Design Decisions

- **Kimball 4-step methodology** — business process, grain, dimensions, facts. Every decision driven by the business question being answered
- **Surrogate keys** — dbt_utils.generate_surrogate_key() MD5 hash on natural keys. Stable and deterministic regardless of rebuild order
- **DIM_DATE YYYYMMDD integer SK** — self-documenting and enables date range queries without joining the dimension
- **Role-playing dimension** — dim_date joined four times in fact table for snapshot, join, exit and promotion dates
- **Quarantine pattern** — bad data captured with failure_reason, not silently dropped. Full visibility into what failed and why
- **Seed INNER JOIN validation** — seeds act as allowed-value filters. Invalid rows excluded from silver automatically
- **SCD2 on DIM_EMPLOYEE** — valid_from, valid_to, is_current ready for historical tracking when multi-period data arrives
- **LEFT JOIN for termination_reason** — active employees have NULL termination_reason and pass through with NULL labels
- **severity: warn on singular tests** — manager hierarchy violations surface without blocking downstream gold model builds
- **No inline SQL comments** — all documentation lives in dbt yaml properties files. SQL stays clean and readable
- **Fact table pulls SKs from dims** — joins gold dims on natural keys to get surrogate keys — no MD5 recalculation in fact

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
├── macros/
├── packages.yml
└── dbt_project.yml
```

# HR Analytics dbt Project

**GitHub:** https://github.com/epvidya/Hr_Analytics_dbt_Project

## Overview

End-to-end HR Analytics data pipeline built on Snowflake using dbt. Implements Medallion Architecture (Bronze to Silver to Gold) with a Kimball-style Star Schema in the Gold layer. Covers raw data ingestion from AWS S3 through transformation and validation to dimensional modelling — backed by 121 automated data quality tests and 10 business analytics queries.

## Architecture

```
S3 → COPY INTO → Staging → Bronze (dbt view) → Silver (dbt table) → Gold (Star Schema)
```

## Tech Stack

- **Snowflake** — data warehouse (COPY INTO, storage integration, compute warehouse)
- **dbt** — transformations, testing, documentation, seed management, dbt_utils package
- **AWS S3** — raw file storage with storage integration and file format management
- **Python** — pandas for data generation, Streamlit for visualisation
- **Git / GitHub** — version control with documented commit history

## Layers

### Bronze
Raw view on top of staging table. All 52 columns remain VARCHAR — no transformations. Not_null and unique tests on critical columns. Constant columns (employee_count, over_18, standard_hours) dropped in silver.

### Silver
- `silver_hr_cleaned` — 200 employees fully cleaned and validated. TRY_CAST, TRY_TO_DATE, INITCAP, TRIM, CASE statement for business_travel dirty values. 10 seed tables as allowed-value validators via INNER JOIN. LEFT JOIN for termination_reason on active employees.
- `silver_hr_quarantine` — Rejected rows captured with ARRAY_CONSTRUCT_COMPACT failure_reason column. Shows which validation failed and what the raw value was.
- 121 dbt generic tests — not_null, accepted_values, relationships to all seeds
- 2 singular tests — manager hierarchy business rules with severity: warn

### Gold — Dimensions
- `dim_date` — 7,670 rows. Recursive CTE covering calendar year, fiscal year (April start), ISO week numbers and US day-of-week mapping. SK is YYYYMMDD integer — self-documenting and enables range queries without joining.
- `dim_employee` — 200 rows. SCD2 ready with valid_from, valid_to, is_current columns for historical tracking.
- `dim_manager` — ~30 rows. Self join on silver_hr_cleaned. Only employees who appear as manager_id are included.
- `dim_job_role` — ~26 rows. DISTINCT job_role + job_level combinations. Natural key is both columns together.
- `dim_org` — ~9 rows. DISTINCT department + business_travel combinations.
- `dim_location` — 11 rows. Cities with state, region and cost_center from seed_location.

### Gold — Fact
- `fact_employee_snapshot` — 200 rows. Grain: one row per employee per snapshot date. dim_date is a role-playing dimension joined four times — snapshot_date_sk, join_date_sk, exit_date_sk, last_promotion_date_sk. SKs pulled from dims via natural key joins — no MD5 recalculation in fact.

## Seeds

10 reference tables loaded via `dbt seed`. Each acts as an allowed-value validator in silver via INNER JOIN — invalid rows go to quarantine with a failure reason.

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
- **Gold tests** — surrogate key uniqueness, date_sk relationships to dim_date, manager_id relationship to dim_employee
- **2 singular tests** — manager hierarchy rules with severity: warn so violations surface without blocking pipeline

## Analyses

10 SQL queries in the `analyses/` folder. Compile with `dbt compile --select <filename>` then run compiled SQL in Snowflake.

- `attrition_rate.sql` — Attrition rate and voluntary vs involuntary split by department, job level and recruitment source
- `headcount_trend.sql` — Headcount trends with FTE vs non-FTE and overtime breakdown by department and region
- `compensation_distribution.sql` — Salary band distribution and band compliance rate by department and job level
- `tenure_analysis.sql` — Tenure bands, satisfaction by tenure group and attrition rate by tenure
- `promotion_cycle_analysis.sql` — Promotion cycle using DATEDIFF on actual dates and overdue promotion detection
- `dept_satisfaction_trend.sql` — Department satisfaction ranking using RANK window function partitioned by month
- `top_employee_satisfaction.sql` — Employee with highest job satisfaction per month using DENSE_RANK and QUALIFY
- `high_performer_attrition.sql` — High performers who already left — post mortem by termination reason and tenure
- `high_performer_dissatisfied.sql` — High performers still employed with low satisfaction — early warning list
- `high_performer_flight_risk.sql` — Flight risk scoring model with 6 factors and Critical/High/Medium/Low classification

## Key Design Decisions

- **Kimball 4-step methodology** — business process, grain, dimensions, facts. Every decision driven by the business question being answered
- **Surrogate keys** — dbt_utils.generate_surrogate_key() MD5 hash on natural keys. Stable and deterministic regardless of rebuild order
- **DIM_DATE YYYYMMDD integer SK** — self-documenting and enables date range queries without joining the dimension
- **Role-playing dimension** — dim_date joined four times in fact table for snapshot, join, exit and promotion dates
- **Quarantine pattern** — bad data captured with failure_reason, not silently dropped. Full visibility into what failed and why
- **Seed INNER JOIN validation** — seeds act as allowed-value filters. Invalid rows excluded from silver automatically
- **SCD2 on DIM_EMPLOYEE** — valid_from, valid_to, is_current ready for historical tracking when multi-period data arrives
- **LEFT JOIN for termination_reason** — active employees have NULL termination_reason and pass through with NULL labels
- **severity: warn on singular tests** — manager hierarchy violations surface without blocking downstream gold model builds
- **No inline SQL comments** — all documentation lives in dbt yaml properties files. SQL stays clean and readable
- **Fact table pulls SKs from dims** — joins gold dims on natural keys to get surrogate keys — no MD5 recalculation in fact

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
├── macros/
├── packages.yml
└── dbt_project.yml
```

## How to Run

- `dbt deps` — install dbt_utils package
- `dbt seed` — load all 10 reference tables into seeds schema
- `dbt build` — build all models and run all tests in dependency order
- `dbt compile --select attrition_rate` — compile analysis SQL for Snowflake