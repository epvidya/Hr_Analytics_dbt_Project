## What is the attrition breakdown for January 2024 — how many employees are active, how many left voluntarily, and how many were involuntarily terminated per department?##

import streamlit as st
from snowflake.snowpark.context import get_active_session

session = get_active_session()
st.header("HR Analytics - Attrition Category per Department by Month")

def get_attrition_category(snapshot):
   
    return session.sql(f"""
        select * from
        HR_ANALYTICS_DBT.GOLD.DT_ATTRITION_SUMMARY
        where WHERE f.snapshot_date_sk   = {snapshot}
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
st.subheader("Detail")
st.dataframe(df)
st.divider()

##Kpi cards
active= int(df[df['CATEGORY']=='Active'] ['EMPLOYEE_COUNT'].sum())
voluntary=int(df[df['CATEGORY']=='Voluntary'] ['EMPLOYEE_COUNT'].sum())
involuntary=int(df[df['CATEGORY']=='Involuntary'] ['EMPLOYEE_COUNT'].sum())
total=active+voluntary+involuntary

col1,col2,col3,col4 = st.columns(4)
col1.metric("Active Employees",active)
col2.metric("Voluntary Attrited", voluntary)
col3.metric("Involuntary Attrited", involuntary)
col4.metric("Total Employees", total)

##Bar Chart
st.subheader("Headcount by Department and Category")
st.divider()
pivot_df = df.pivot(
    index='DEPARTMENT',
    columns='CATEGORY',
    values='EMPLOYEE_COUNT'
).fillna(0)
st.bar_chart(pivot_df)