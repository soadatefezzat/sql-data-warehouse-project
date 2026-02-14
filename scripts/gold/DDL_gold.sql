/* 
==========================================================================================================
DDL Script: Create Gold Views
==========================================================================================================

Script Purpose:
This script creates the views for the Gold layer in the data warehouse.
The Gold layer represents the final dimensions and fact tables (star schema).

Each view combines data from the Silver layer to produce a clean, enriched, 
and business‑ready dataset.

Usage:
These views can be queried directly for analytics and reporting.

==========================================================================================================
*/


USE [Banking Transactions];
GO

-- Drop table if exists
IF OBJECT_ID('gold.dim_users', 'v') IS NOT NULL
BEGIN
    DROP VIEW gold.dim_users;
END
GO

CREATE VIEW gold.dim_users AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY user_id) AS user_key,   -- surrogate key
    user_id,                                            -- natural key
    current_age,
    retirement_age,
    birth_year,
    birth_month,
    gender,
    address,
    latitude,
    longitude,
    per_capita_income,
    yearly_income,
    total_dept,
    credit_score,
    num_credit_cards,
    dwh_create_date
FROM silver.users_data;

-- Drop table if exists
IF OBJECT_ID('gold.dim_cards', 'v') IS NOT NULL
BEGIN
    DROP VIEW gold.dim_cards;
END
GO

CREATE VIEW gold.dim_cards AS
SELECT
    ROW_NUMBER() OVER (ORDER BY card_id) AS card_key,   -- surrogate key
    card_id,                                            -- natural key
    client_id,
    card_type,
    card_brand,
    card_number,
    expires,
    cvv,
    has_chip,
    num_cards_issued,
    credit_limit,
    acct_open_date,
    year_bin_last_changed,
    card_on_dark_web,
    dwh_create_date
FROM silver.cards_data;

-- Drop table if exists
IF OBJECT_ID('gold.fact_transactions', 'v') IS NOT NULL
BEGIN
    DROP VIEW gold.fact_transactions;
END
GO

CREATE VIEW gold.fact_transactions AS
SELECT
    t.transaction_id,
    
    u.user_key,     -- surrogate key from dim_users
    c.card_key,     -- surrogate key from dim_cards
    
    t.transaction_date,
    t.merchant_id,
    t.merchant_city,
    t.merchant_state,
    t.amount,
    t.use_chip,
    t.zip,
    t.mcc,
    t.errors,
    t.dwh_create_date
FROM silver.transactions_data t
LEFT JOIN gold.dim_users u
    ON t.client_id = u.user_id
LEFT JOIN gold.dim_cards c
    ON t.card_id = c.card_id;
