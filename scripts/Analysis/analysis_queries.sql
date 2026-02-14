/*
======================================================
Analysis Queries
======================================================

Script Purpose:
This script performs analytical queries on the Gold layer 
(star schema) to extract business insights related to 
transactions, users, and card behavior.

These analyses include:
- Transaction trends over time
- User and card activity patterns
- Fraud and anomaly detection signals
- Spending behavior and demographic insights
- Card performance and risk indicators

Usage Notes:
- Run these queries after the Gold layer has been fully loaded.
- Use the results for reporting, dashboards, and advanced analytics.
- Investigate any unusual patterns or anomalies revealed by the queries.

======================================================
*/


--Total number of transactions per year
--===================================================
SELECT 
    YEAR(transaction_date) AS txn_year,
    COUNT(*) AS TrnsPerYear
FROM gold.fact_transactions
GROUP BY YEAR(transaction_date)
ORDER BY txn_year;


--===================================================
--Total number of transactions per month in 2010 & 2011 + avg amount per month
--===================================================
SELECT  
    MONTH(transaction_date) AS [month],
    SUM(CASE WHEN YEAR(transaction_date) = 2010 THEN 1 ELSE 0 END) AS year2010,
    SUM(CASE WHEN YEAR(transaction_date) = 2011 THEN 1 ELSE 0 END) AS year2011,
    AVG(amount) AS AmountAvg
FROM gold.fact_transactions
WHERE YEAR(transaction_date) IN (2010, 2011)
GROUP BY MONTH(transaction_date)
ORDER BY [month], AmountAvg;

--===================================================
--number of transactions & number of cards & avg amount (per user)
--===================================================
SELECT 
    user_id,
    CardsCount,
    ClientTransCount,
    ROW_NUMBER() OVER (ORDER BY ClientTransCount DESC) AS TransRanking,
    AmountAvg
FROM (
    SELECT 
        u.user_id,
        COUNT(f.transaction_id) AS ClientTransCount,
        AVG(f.amount) AS AmountAvg,
        COUNT(DISTINCT c.card_id) AS CardsCount
    FROM gold.fact_transactions f
    JOIN gold.dim_users u ON f.user_key = u.user_key
    JOIN gold.dim_cards c ON f.card_key = c.card_key
    GROUP BY u.user_id
) AS clients
ORDER BY TransRanking;

--===================================================
--number of transactions & avg amount (per card)
--===================================================
SELECT 
    card_id,
    TransCount,
    ROW_NUMBER() OVER (ORDER BY TransCount DESC) AS TransRank,
    AmountAvg
FROM (
    SELECT 
        c.card_id,
        COUNT(f.transaction_id) AS TransCount,
        AVG(f.amount) AS AmountAvg
    FROM gold.fact_transactions f
    JOIN gold.dim_cards c ON f.card_key = c.card_key
    GROUP BY c.card_id
) AS cards
ORDER BY TransRank;

--===================================================
--cards number per user
--===================================================
SELECT 
    u.user_id,
    COUNT(DISTINCT c.card_id) AS CardsCount
FROM gold.fact_transactions f
JOIN gold.dim_users u ON f.user_key = u.user_key
JOIN gold.dim_cards c ON f.card_key = c.card_key
GROUP BY u.user_id;

--===================================================
--Transactions per card type
--===================================================
SELECT 
    c.card_type,
    COUNT(DISTINCT f.transaction_id) AS TransCount,
    COUNT(DISTINCT u.user_id) AS ClientsCount
FROM gold.fact_transactions f
JOIN gold.dim_cards c ON f.card_key = c.card_key
JOIN gold.dim_users u ON f.user_key = u.user_key
GROUP BY c.card_type;

--===================================================
--Transactions per card brand
--===================================================
SELECT 
    c.card_brand,
    COUNT(DISTINCT f.transaction_id) AS TransCount,
    COUNT(DISTINCT u.user_id) AS ClientsCount
FROM gold.fact_transactions f
JOIN gold.dim_cards c ON f.card_key = c.card_key
JOIN gold.dim_users u ON f.user_key = u.user_key
GROUP BY c.card_brand;

--===================================================
--Transactions in different locations within short time
--===================================================
SELECT 
    u1.user_id,
    t1.transaction_id AS txn1,
    t2.transaction_id AS txn2,
    t1.merchant_city AS city1,
    t2.merchant_city AS city2,
    t1.transaction_date AS txn1_date,
    t2.transaction_date AS txn2_date
FROM gold.fact_transactions t1
JOIN gold.fact_transactions t2
    ON t1.user_key = t2.user_key
   AND t1.transaction_id <> t2.transaction_id
   AND ABS(DATEDIFF(MINUTE, t1.transaction_date, t2.transaction_date)) < 30
JOIN gold.dim_users u1 ON t1.user_key = u1.user_key
JOIN gold.dim_users u2 ON t2.user_key = u2.user_key
WHERE t1.merchant_city <> t2.merchant_city
   OR t1.merchant_state <> t2.merchant_state;

--===================================================
--Multiple transactions in short time (per hour per day)
--===================================================
SELECT 
    u.user_id,
    COUNT(f.transaction_id) AS txn_count,
    MIN(f.transaction_date) AS first_txn,
    MAX(f.transaction_date) AS last_txn
FROM gold.fact_transactions f
JOIN gold.dim_users u ON f.user_key = u.user_key
GROUP BY 
    u.user_id,
    CAST(f.transaction_date AS DATE),
    DATEPART(HOUR, f.transaction_date)
HAVING COUNT(f.transaction_id) > 5;

--===================================================
--Most popular card types among demographics
--===================================================
SELECT  
    u.current_age,
    u.gender,
    c.card_type,
    COUNT(f.transaction_id) AS txn_count
FROM gold.fact_transactions f
JOIN gold.dim_users u ON f.user_key = u.user_key
JOIN gold.dim_cards c ON f.card_key = c.card_key
GROUP BY u.gender, u.current_age, c.card_type
ORDER BY u.gender, u.current_age, txn_count DESC;

--===================================================
--Users generating highest transaction value per card type
--===================================================
SELECT 
    u.user_id,
    c.card_type,
    SUM(f.amount) AS total_spent,
    ROW_NUMBER() OVER (PARTITION BY c.card_type ORDER BY SUM(f.amount) DESC) AS rank_within_card
FROM gold.fact_transactions f
JOIN gold.dim_users u ON f.user_key = u.user_key
JOIN gold.dim_cards c ON f.card_key = c.card_key
GROUP BY u.user_id, c.card_type
ORDER BY c.card_type, total_spent DESC;

--===================================================
--High amount outliers
--===================================================
SELECT 
    u.user_id,
    f.transaction_id,
    f.amount
FROM gold.fact_transactions f
JOIN gold.dim_users u ON f.user_key = u.user_key
WHERE f.amount > 10000;

--===================================================
--Transactions with errors
--===================================================
SELECT 
    u.user_id,
    f.transaction_id,
    f.errors
FROM gold.fact_transactions f
JOIN gold.dim_users u ON f.user_key = u.user_key
WHERE f.errors IS NOT NULL;

--===================================================
--Chip vs non-chip transaction counts
--===================================================
SELECT 
    c.has_chip,
    COUNT(f.transaction_id) AS txn_count
FROM gold.fact_transactions f
JOIN gold.dim_cards c ON f.card_key = c.card_key
GROUP BY c.has_chip;

--===================================================
--Unusual locations (rare locations per user)
--===================================================
SELECT 
    u.user_id,
    f.merchant_city,
    f.merchant_state,
    f.zip,
    COUNT(f.transaction_id) AS txn_count
FROM gold.fact_transactions f
JOIN gold.dim_users u ON f.user_key = u.user_key
GROUP BY u.user_id, f.merchant_city, f.merchant_state, f.zip
HAVING COUNT(f.transaction_id) < 2;

--===================================================
--% cards with chip
--===================================================
SELECT 
    100.0 * SUM(CASE WHEN c.has_chip = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) AS pct_chip_cards
FROM gold.dim_cards c;

--===================================================
--% cards on dark web
--===================================================
SELECT 
    100.0 * SUM(CASE WHEN c.card_on_dark_web = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) AS pct_dark_web_cards
FROM gold.dim_cards c;

--===================================================
--Expired cards usage
--===================================================
SELECT 
    u.user_id,
    c.card_id,
    f.transaction_id,
    f.transaction_date,
    c.expires
FROM gold.fact_transactions f
JOIN gold.dim_cards c ON f.card_key = c.card_key
JOIN gold.dim_users u ON f.user_key = u.user_key
WHERE f.transaction_date > c.expires;

--===================================================
--Income distribution
--===================================================
SELECT 
    u.user_id,
    AVG(u.per_capita_income) AS AvgPerCapitaIncome,
    AVG(u.yearly_income) AS AvgYearlyIncome
FROM gold.dim_users u
GROUP BY u.user_id;

--===================================================
--Debt-to-Income (DTI)
--===================================================
SELECT 
    u.user_id,
    u.total_dept,
    u.yearly_income,
    CAST(u.total_dept AS FLOAT) / NULLIF(u.yearly_income, 0) AS dti_ratio
FROM gold.dim_users u;
