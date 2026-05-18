import streamlit as st
from snowflake.snowpark.context import get_active_session

session = get_active_session()
st.header("HR Analytics - Attrition Split by Month")
def get_attrition_category(snapshot):
   
    return session.sql(f"""
        WITH base AS (
            SELECT
                f.termination_category      AS CATEGORY,
                f.snapshot_date_sk          AS SNAPSHOT_DATE,
                d.month_year                AS MONTH_YEAR
            FROM HR_ANALYTICS_DBT.GOLD.FACT_EMPLOYEE_SNAPSHOT f
            JOIN HR_ANALYTICS_DBT.GOLD.DIM_DATE d
                ON f.snapshot_date_sk       = d.date_sk
            WHERE f.snapshot_date_sk        = {snapshot}
        )
        SELECT
            category,
            snapshot_date,
            month_year,
            COUNT(*)                        AS EMPLOYEE_COUNT
        FROM base
        GROUP BY
            category,
            snapshot_date,
            month_year
        ORDER BY
            snapshot_date,
            category
    """).to_pandas()

def get_snapshot_dates():
   
    return session.sql("""
        SELECT DISTINCT
            f.snapshot_date_sk,
            d.month_year
        FROM HR_ANALYTICS_DBT.GOLD.FACT_EMPLOYEE_SNAPSHOT f
        JOIN HR_ANALYTICS_DBT.GOLD.DIM_DATE d
            ON f.snapshot_date_sk = d.date_sk
        ORDER BY f.snapshot_date_sk
    """).to_pandas()

dates_df = get_snapshot_dates()
snapshot_date = st.selectbox(
    "Select Snapshot Month",
    options=dates_df['SNAPSHOT_DATE_SK'].tolist(),
    format_func=lambda x: dates_df[
        dates_df['SNAPSHOT_DATE_SK'] == x
    ]['MONTH_YEAR'].iloc[0]
)


df = get_attrition_category(snapshot_date)
##st.write(df.columns.tolist())
st.dataframe(df)
st.divider()
##Kpi cards
active= int(df[df['CATEGORY']=='Active'] ['EMPLOYEE_COUNT'].iloc[0])
voluntary=int(df[df['CATEGORY']=='Voluntary'] ['EMPLOYEE_COUNT'].iloc[0])
involuntary=int(df[df['CATEGORY']=='Involuntary'] ['EMPLOYEE_COUNT'].iloc[0])
total=active+voluntary+involuntary

col1,col2,col3,col4 = st.columns(4)
col1.metric("Active Employees",active)
col2.metric("Voluntary Attrited", voluntary)
col3.metric("Involuntary Attrited", involuntary)
col4.metric("Total Employees", total)

st.divider()
st.bar_chart(df.set_index('CATEGORY')['EMPLOYEE_COUNT'])