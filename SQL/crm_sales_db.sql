-- CRM Sales Performance Analysis
-- MySQL schema and analysis queries used for the Power BI dashboard.
-- Note: This script defines the schema and analysis queries. Data loading is not
-- included here; import the CRM source data into the tables before running the
-- analysis queries.

CREATE DATABASE IF NOT EXISTS crm_sales;
USE crm_sales;

-- ============================================================
-- 1. Database schema
-- ============================================================

CREATE TABLE IF NOT EXISTS accounts (
    accounts_name VARCHAR(100) PRIMARY KEY,
    sector VARCHAR(50),
    year_established INT,
    revenue DECIMAL(12,2),
    employees INT,
    office_location VARCHAR(100),
    subsidiary_of VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS products (
    product VARCHAR(100) PRIMARY KEY,
    series VARCHAR(50),
    sales_price INT
);

CREATE TABLE IF NOT EXISTS sales_teams (
    sales_agent VARCHAR(100) PRIMARY KEY,
    manager VARCHAR(100),
    regional_office VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS sales_pipeline (
    opportunity_id VARCHAR(20) PRIMARY KEY,
    sales_agent VARCHAR(100),
    product VARCHAR(100),
    account_name VARCHAR(100),
    deal_stage VARCHAR(30),
    engage_date DATE,
    close_date DATE,
    close_value DECIMAL(12,2)
);

-- Optional staging structure used during data import/cleaning.
-- Kept as comments so the portfolio script stays focused on the final model.
--
-- CREATE TABLE sales_pipeline_staging (
--     opportunity_id VARCHAR(20),
--     sales_agent VARCHAR(100),
--     product VARCHAR(100),
--     account_name VARCHAR(100),
--     deal_stage VARCHAR(30),
--     engage_date VARCHAR(20),
--     close_date VARCHAR(20),
--     close_value VARCHAR(30)
-- );

-- ============================================================
-- 2. Basic validation
-- ============================================================

SELECT DATABASE() AS active_database;

SELECT 'accounts' AS table_name, COUNT(*) AS row_count FROM accounts
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sales_pipeline', COUNT(*) FROM sales_pipeline
UNION ALL
SELECT 'sales_teams', COUNT(*) FROM sales_teams;

-- ============================================================
-- 3. Overall pipeline analysis
-- ============================================================

-- Opportunities and value by deal stage
SELECT
    deal_stage,
    COUNT(*) AS opportunities,
    SUM(close_value) AS total_value
FROM sales_pipeline
GROUP BY deal_stage
ORDER BY opportunities DESC;

-- Overall closed-deal win rate
SELECT
    COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END) AS won_deals,
    COUNT(CASE WHEN deal_stage = 'Lost' THEN 1 END) AS lost_deals,
    ROUND(
        100.0 * COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END)
        / NULLIF(
            COUNT(CASE WHEN deal_stage IN ('Won', 'Lost') THEN 1 END),
            0
        ),
        2
    ) AS win_rate_percent
FROM sales_pipeline;

-- Overall won-deal KPIs
SELECT
    COUNT(*) AS won_deals,
    SUM(close_value) AS total_won_revenue,
    ROUND(AVG(close_value), 2) AS average_won_deal_value
FROM sales_pipeline
WHERE deal_stage = 'Won';

-- ============================================================
-- 4. Product performance
-- ============================================================

-- Won revenue by product
SELECT
    product,
    COUNT(*) AS won_deals,
    SUM(close_value) AS total_revenue
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY product
ORDER BY total_revenue DESC;

-- Total opportunities by product
SELECT
    product,
    COUNT(*) AS total_deals
FROM sales_pipeline
GROUP BY product
ORDER BY total_deals DESC;

-- Win rate by product
SELECT
    product,
    COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END) AS won_deals,
    COUNT(CASE WHEN deal_stage = 'Lost' THEN 1 END) AS lost_deals,
    ROUND(
        100.0 * COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END)
        / NULLIF(
            COUNT(CASE WHEN deal_stage IN ('Won', 'Lost') THEN 1 END),
            0
        ),
        2
    ) AS win_rate_percent
FROM sales_pipeline
GROUP BY product
ORDER BY win_rate_percent DESC;

-- Won deal count, revenue, and average deal value by product
SELECT
    product,
    COUNT(*) AS won_deals,
    SUM(close_value) AS total_revenue,
    ROUND(AVG(close_value), 2) AS average_deal_value
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY product
ORDER BY total_revenue DESC;

-- ============================================================
-- 5. Sales agent performance
-- ============================================================

SELECT
    sales_agent,
    COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END) AS won_deals,
    COUNT(CASE WHEN deal_stage = 'Lost' THEN 1 END) AS lost_deals,
    SUM(CASE WHEN deal_stage = 'Won' THEN close_value ELSE 0 END) AS won_revenue,
    ROUND(
        100.0 * COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END)
        / NULLIF(
            COUNT(CASE WHEN deal_stage IN ('Won', 'Lost') THEN 1 END),
            0
        ),
        2
    ) AS win_rate_percent
FROM sales_pipeline
GROUP BY sales_agent
ORDER BY won_revenue DESC;

-- ============================================================
-- 6. Regional and manager performance
-- ============================================================

-- Regional performance
SELECT
    st.regional_office,
    COUNT(CASE WHEN sp.deal_stage = 'Won' THEN 1 END) AS won_deals,
    COUNT(CASE WHEN sp.deal_stage = 'Lost' THEN 1 END) AS lost_deals,
    SUM(CASE WHEN sp.deal_stage = 'Won' THEN sp.close_value ELSE 0 END) AS won_revenue,
    ROUND(
        100.0 * COUNT(CASE WHEN sp.deal_stage = 'Won' THEN 1 END)
        / NULLIF(
            COUNT(CASE WHEN sp.deal_stage IN ('Won', 'Lost') THEN 1 END),
            0
        ),
        2
    ) AS win_rate_percent
FROM sales_pipeline sp
JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent
GROUP BY st.regional_office
ORDER BY won_revenue DESC;

-- Manager performance
SELECT
    st.manager,
    COUNT(CASE WHEN sp.deal_stage = 'Won' THEN 1 END) AS won_deals,
    COUNT(CASE WHEN sp.deal_stage = 'Lost' THEN 1 END) AS lost_deals,
    SUM(CASE WHEN sp.deal_stage = 'Won' THEN sp.close_value ELSE 0 END) AS won_revenue,
    ROUND(
        100.0 * COUNT(CASE WHEN sp.deal_stage = 'Won' THEN 1 END)
        / NULLIF(
            COUNT(CASE WHEN sp.deal_stage IN ('Won', 'Lost') THEN 1 END),
            0
        ),
        2
    ) AS win_rate_percent
FROM sales_pipeline sp
JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent
GROUP BY st.manager
ORDER BY won_revenue DESC;

-- ============================================================
-- 7. Monthly sales performance
-- ============================================================

-- Monthly closed-deal performance
SELECT
    DATE_FORMAT(close_date, '%Y-%m') AS close_month,
    COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END) AS won_deals,
    COUNT(CASE WHEN deal_stage = 'Lost' THEN 1 END) AS lost_deals,
    SUM(CASE WHEN deal_stage = 'Won' THEN close_value ELSE 0 END) AS won_revenue
FROM sales_pipeline
WHERE close_date IS NOT NULL
  AND deal_stage IN ('Won', 'Lost')
GROUP BY DATE_FORMAT(close_date, '%Y-%m')
ORDER BY close_month;

-- Monthly won revenue and won-deal count
SELECT
    DATE_FORMAT(close_date, '%Y-%m') AS month,
    SUM(close_value) AS won_revenue,
    COUNT(*) AS won_deals
FROM sales_pipeline
WHERE deal_stage = 'Won'
  AND close_date IS NOT NULL
GROUP BY DATE_FORMAT(close_date, '%Y-%m')
ORDER BY month;

-- Monthly closed win rate
SELECT
    DATE_FORMAT(close_date, '%Y-%m') AS month,
    COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END) AS won_deals,
    COUNT(CASE WHEN deal_stage = 'Lost' THEN 1 END) AS lost_deals,
    ROUND(
        100.0 * COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END)
        / NULLIF(
            COUNT(CASE WHEN deal_stage IN ('Won', 'Lost') THEN 1 END),
            0
        ),
        2
    ) AS win_rate_percent
FROM sales_pipeline
WHERE close_date IS NOT NULL
  AND deal_stage IN ('Won', 'Lost')
GROUP BY DATE_FORMAT(close_date, '%Y-%m')
ORDER BY month;

-- ============================================================
-- 8. Open pipeline analysis
-- ============================================================

-- Open opportunities by product
SELECT
    product,
    COUNT(*) AS open_deals,
    SUM(close_value) AS open_pipeline_value
FROM sales_pipeline
WHERE deal_stage IN ('Engaging', 'Prospecting')
GROUP BY product
ORDER BY open_deals DESC;

-- Overall open-pipeline counts and available values
SELECT
    COUNT(*) AS open_deals,
    COUNT(close_value) AS open_deals_with_value,
    COALESCE(SUM(close_value), 0) AS open_value
FROM sales_pipeline
WHERE deal_stage IN ('Engaging', 'Prospecting');

-- Open opportunities by sales agent
SELECT
    sales_agent,
    COUNT(*) AS open_deals
FROM sales_pipeline
WHERE deal_stage IN ('Engaging', 'Prospecting')
GROUP BY sales_agent
ORDER BY open_deals DESC;

-- Open opportunities by stage
SELECT
    deal_stage,
    COUNT(*) AS open_deals
FROM sales_pipeline
WHERE deal_stage IN ('Engaging', 'Prospecting')
GROUP BY deal_stage
ORDER BY open_deals DESC;

-- ============================================================
-- 9. Additional stage distribution
-- ============================================================

SELECT
    deal_stage,
    COUNT(*) AS opportunities,
    ROUND(
        100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM sales_pipeline), 0),
        2
    ) AS percentage
FROM sales_pipeline
GROUP BY deal_stage
ORDER BY opportunities DESC;
