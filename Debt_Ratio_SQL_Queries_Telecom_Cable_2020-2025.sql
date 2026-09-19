-- TELECOM DEBT ANALYSIS - COMPLETE PROJECT
-- SQL Setup + All 16 Queries

-- STEP 1: CREATE DATABASE
CREATE DATABASE telecom_analysis;

-- STEP 2: CONNECT TO DATABASE
\c telecom_analysis

-- STEP 3: CREATE TABLE
CREATE TABLE telecom_data (
  costat VARCHAR(50),
  curcd VARCHAR(10),
  datafmt VARCHAR(50),
  indfmt VARCHAR(50),
  consol VARCHAR(50),
  tic VARCHAR(20),
  datadate VARCHAR(20),
  gvkey INTEGER,
  conm VARCHAR(200),
  zipcode TEXT,
  sic INTEGER,
  fyear INTEGER,
  at NUMERIC(15,2),
  ceq NUMERIC(15,2),
  dlc NUMERIC(15,2),
  dltt NUMERIC(15,2),
  lt NUMERIC(15,2),
  re NUMERIC(15,2),
  cogs NUMERIC(15,2),
  ebit NUMERIC(15,2),
  revt NUMERIC(15,2),
  xint NUMERIC(15,2),
  oancf NUMERIC(15,2),
  csho NUMERIC(15,2),
  prcc_f NUMERIC(15,2)
);

-- STEP 4: IMPORT DATA FROM CSV
COPY telecom_data FROM 'Path to your original dataset CSV file'
DELIMITER ','
CSV HEADER;

-- STEP 5: VERIFY DATA LOADED
SELECT COUNT(*) FROM telecom_data;

-- QUERY 1: Total Debt Overview
\COPY (
SELECT 
  conm as company_name,
  AVG(dltt + dlc) as avg_total_debt,
  MAX(dltt + dlc) as max_total_debt,
  MIN(dltt + dlc) as min_total_debt,
  COUNT(DISTINCT fyear) as years_analyzed
FROM telecom_data
GROUP BY conm
ORDER BY avg_total_debt DESC
) TO 'Path to output folder/01_total_debt_by_company.csv' WITH (FORMAT csv, HEADER);

-- QUERY 2: Debt Trend Over Time
\COPY (
SELECT 
  conm as company_name,
  fyear as fiscal_year,
  (dltt + dlc) as total_debt,
  LAG(dltt + dlc) OVER (PARTITION BY conm ORDER BY fyear) as previous_year_debt,
  ROUND((dltt + dlc) - LAG(dltt + dlc) OVER (PARTITION BY conm ORDER BY fyear), 0) as debt_change
FROM telecom_data
ORDER BY conm, fyear
) TO 'Path to output folder/02_debt_trend_over_time.csv' WITH (FORMAT csv, HEADER);

-- QUERY 3: Debt-to-Equity Ratio
\COPY (
SELECT 
  conm as company_name,
  fyear as fiscal_year,
  (dltt + dlc) as total_debt,
  ceq as common_equity,
  ROUND(((dltt + dlc) / ceq)::NUMERIC, 2) as debt_to_equity_ratio,
  CASE 
    WHEN (dltt + dlc) / ceq < 0.5 THEN 'Conservative'
    WHEN (dltt + dlc) / ceq < 1.0 THEN 'Moderate'
    WHEN (dltt + dlc) / ceq < 1.5 THEN 'Aggressive'
    ELSE 'Very High'
  END as leverage_category
FROM telecom_data
ORDER BY conm, fyear
) TO 'Path to output folder/03_debt_to_equity_ratio.csv' WITH (FORMAT csv, HEADER);

-- QUERY 4: Interest Coverage Ratio
\COPY (
SELECT 
  conm as company_name,
  fyear as fiscal_year,
  ebit,
  xint as interest_expense,
  ROUND((ebit / xint)::NUMERIC, 2) as interest_coverage_ratio,
  CASE 
    WHEN ebit / xint > 10 THEN 'Excellent'
    WHEN ebit / xint > 5 THEN 'Good'
    WHEN ebit / xint > 2.5 THEN 'Fair'
    WHEN ebit / xint > 1.5 THEN 'Weak'
    ELSE 'Very Weak'
  END as coverage_quality
FROM telecom_data
ORDER BY conm, fyear
) TO 'Path to output folder/04_interest_coverage_ratio.csv' WITH (FORMAT csv, HEADER);

-- QUERY 5: Debt Service Coverage Ratio (MODIFIED)
\COPY (
SELECT 
  conm as company_name,
  fyear as fiscal_year,
  oancf as operating_cash_flow,
  xint as interest_expense,
  dlc as current_debt,
  (xint + dlc) as total_debt_service,
  ROUND((oancf / (xint + dlc))::NUMERIC, 2) as debt_service_capacity,
  CASE 
    WHEN oancf / (xint + dlc) > 3.0 THEN 'Excellent'
    WHEN oancf / (xint + dlc) > 2.0 THEN 'Good'
    WHEN oancf / (xint + dlc) > 1.5 THEN 'Adequate'
    WHEN oancf / (xint + dlc) > 1.0 THEN 'Tight'
    ELSE 'Stressed'
  END as debt_service_quality
FROM telecom_data
ORDER BY conm, fyear
) TO 'Path to output folder/05_debt_service_coverage.csv' WITH (FORMAT csv, HEADER);

-- QUERY 6: Weighted Average Cost of Debt (WACD)
\COPY (
SELECT 
  conm as company_name,
  fyear as fiscal_year,
  xint as interest_expense,
  (dltt + dlc) as total_debt,
  ROUND((100 * (xint / (dltt + dlc)))::NUMERIC, 2) as wacd_percent,
  CASE 
    WHEN (100 * (xint / (dltt + dlc))) < 2.0 THEN 'Excellent'
    WHEN (100 * (xint / (dltt + dlc))) < 3.0 THEN 'Good'
    WHEN (100 * (xint / (dltt + dlc))) < 4.0 THEN 'Moderate'
    ELSE 'High'
  END as cost_quality
FROM telecom_data
ORDER BY conm, fyear
) TO 'Path to output folder/06_weighted_avg_cost_of_debt.csv' WITH (FORMAT csv, HEADER);

-- QUERY 8: Debt-to-Assets Ratio
\COPY (
SELECT 
  conm as company_name,
  fyear as fiscal_year,
  (dltt + dlc) as total_debt,
  at as total_assets,
  ROUND(((dltt + dlc) / at)::NUMERIC, 2) as debt_to_assets_ratio,
  ROUND((100 * ((dltt + dlc) / at))::NUMERIC, 1) as pct_debt_financed
FROM telecom_data
ORDER BY conm, fyear
) TO 'Path to output folder/08_debt_to_assets.csv' WITH (FORMAT csv, HEADER);

-- QUERY 9: Leverage Comparison (Master Dashboard)
\COPY (
SELECT 
  conm as company_name,
  fyear as fiscal_year,
  (dltt + dlc) as total_debt,
  ceq as common_equity,
  oancf as operating_cash_flow,
  ebit,
  xint as interest_expense,
  ROUND(((dltt + dlc) / ceq)::NUMERIC, 2) as d_e_ratio,
  ROUND((ebit / xint)::NUMERIC, 2) as interest_coverage,
  ROUND((oancf / (xint + dlc))::NUMERIC, 2) as debt_service_capacity
FROM telecom_data
ORDER BY conm, fyear
) TO 'Path to output folder/09_leverage_comparison.csv' WITH (FORMAT csv, HEADER);

-- QUERY 12: Year-over-Year Changes
\COPY (
SELECT 
  conm as company_name,
  fyear as fiscal_year,
  ROUND(((dltt + dlc) / ceq)::NUMERIC, 2) as d_e_ratio,
  LAG(ROUND(((dltt + dlc) / ceq)::NUMERIC, 2)) OVER (PARTITION BY conm ORDER BY fyear) as previous_year_d_e,
  ROUND((ebit / xint)::NUMERIC, 2) as icr,
  LAG(ROUND((ebit / xint)::NUMERIC, 2)) OVER (PARTITION BY conm ORDER BY fyear) as previous_year_icr,
  CASE 
    WHEN ROUND(((dltt + dlc) / ceq)::NUMERIC, 2) < LAG(ROUND(((dltt + dlc) / ceq)::NUMERIC, 2)) OVER (PARTITION BY conm ORDER BY fyear) THEN 'Improving'
    WHEN ROUND(((dltt + dlc) / ceq)::NUMERIC, 2) > LAG(ROUND(((dltt + dlc) / ceq)::NUMERIC, 2)) OVER (PARTITION BY conm ORDER BY fyear) THEN 'Worsening'
    ELSE 'Flat'
  END as leverage_trend
FROM telecom_data
ORDER BY conm, fyear
) TO 'Path to output folder/12_year_over_year_changes.csv' WITH (FORMAT csv, HEADER);

-- QUERY 13: Debt/EBITDA Ratio
\COPY (
SELECT 
  conm as company_name,
  fyear as fiscal_year,
  (dltt + dlc) as total_debt,
  ebit as ebitda_proxy,
  ROUND(((dltt + dlc) / ebit)::NUMERIC, 2) as debt_to_ebitda_ratio,
  CASE 
    WHEN (dltt + dlc) / ebit < 2.0 THEN 'Conservative'
    WHEN (dltt + dlc) / ebit < 3.0 THEN 'Moderate'
    WHEN (dltt + dlc) / ebit < 4.0 THEN 'High'
    ELSE 'Very High'
  END as leverage_category
FROM telecom_data
ORDER BY conm, fyear
) TO 'Path to output folder/13_debt_to_ebitda_ratio.csv' WITH (FORMAT csv, HEADER);

-- QUERY 14: Debt/Revenue Ratio
\COPY (
SELECT 
  conm as company_name,
  fyear as fiscal_year,
  (dltt + dlc) as total_debt,
  revt as revenue,
  ROUND(((dltt + dlc) / revt)::NUMERIC, 2) as debt_to_revenue_ratio,
  CASE 
    WHEN (dltt + dlc) / revt < 0.5 THEN 'Conservative'
    WHEN (dltt + dlc) / revt < 1.0 THEN 'Moderate'
    WHEN (dltt + dlc) / revt < 1.5 THEN 'Aggressive'
    ELSE 'Very High'
  END as leverage_category
FROM telecom_data
ORDER BY conm, fyear
) TO 'Path to output folder/14_debt_to_revenue_ratio.csv' WITH (FORMAT csv, HEADER);

-- QUERY 15: Net Income/Debt Ratio
\COPY (
SELECT 
  conm as company_name,
  fyear as fiscal_year,
  (ebit - xint) as estimated_net_income,
  (dltt + dlc) as total_debt,
  ROUND((((ebit - xint) / (dltt + dlc))::NUMERIC), 4) as net_income_to_debt_ratio,
  ROUND((100 * ((ebit - xint) / (dltt + dlc)))::NUMERIC, 2) as net_income_to_debt_pct,
  CASE 
    WHEN ((ebit - xint) / (dltt + dlc)) > 0.10 THEN 'Strong'
    WHEN ((ebit - xint) / (dltt + dlc)) > 0.05 THEN 'Good'
    WHEN ((ebit - xint) / (dltt + dlc)) > 0.02 THEN 'Moderate'
    ELSE 'Weak'
  END as profitability_leverage
FROM telecom_data
ORDER BY conm, fyear
) TO 'Path to output folder/15_net_income_to_debt.csv' WITH (FORMAT csv, HEADER);

-- QUERY 16: Balance Sheet Breakdown
\COPY (
SELECT 
  conm as company_name,
  fyear as fiscal_year,
  at as total_assets,
  lt as total_liabilities,
  ceq as total_equity,
  (dltt + dlc) as total_debt,
  ROUND((lt - (dltt + dlc))::NUMERIC, 0) as other_liabilities,
  ROUND(((dltt + dlc) / lt * 100)::NUMERIC, 2) as debt_pct_of_liabilities,
  ROUND(((lt - (dltt + dlc)) / lt * 100)::NUMERIC, 2) as other_liabilities_pct_of_liabilities
FROM telecom_data
ORDER BY conm, fyear
) TO 'Path to output folder/17_balance_sheet_breakdown.csv' WITH (FORMAT csv, HEADER);

-- QUERY 17: Company Zipcode & Assets
\COPY (
SELECT 
  conm as company_name,
  addzip as zipcode,
  at as total_assets
FROM telecom_data
WHERE fyear = 2025
ORDER BY conm
) TO 'Path to output folder/14_company_zipcode_assets.csv' WITH (FORMAT csv, HEADER);
