/*
======================================================
Quality Checks
======================================================

Script Purpose:
This script performs quality checks to validate the integrity, 
consistency, and accuracy of the Gold layer. These checks ensure:

- Uniqueness of surrogate keys in dimension tables
- Referential integrity between fact and dimension tables
- Validation of relationships in the data model for analytical purposes

Usage Notes:
- Run these checks after loading data into the Gold layer
- Investigate and resolve any discrepancies found during the checks

======================================================
*/


--=====================================================
-- Uniqueness of Surrogate Keys in Dimensions
--=====================================================
--Users Dimension
SELECT user_key, COUNT(*) AS c
FROM gold.dim_users
GROUP BY user_key
HAVING COUNT(*) > 1 OR user_key IS NULL;

--Cards Dimension
SELECT card_key, COUNT(*) AS c
FROM gold.dim_cards
GROUP BY card_key
HAVING COUNT(*) > 1 OR card_key IS NULL;

--======================================================
--Uniqueness of Natural Keys in Dimensions
--======================================================
SELECT user_id, COUNT(*) AS c
FROM gold.dim_users
GROUP BY user_id
HAVING COUNT(*) > 1 OR user_id IS NULL;

SELECT card_id, COUNT(*) AS c
FROM gold.dim_cards
GROUP BY card_id
HAVING COUNT(*) > 1 OR card_id IS NULL;

--=======================================================
--Referential Integrity Between Fact and Dimensions
--=======================================================
--Missing User Dimension Keys
SELECT f.transaction_id, u.user_id
FROM gold.fact_transactions f
LEFT JOIN gold.dim_users u ON f.user_key = u.user_key
WHERE u.user_key IS NULL;

--Missing Card Dimension Keys
SELECT f.transaction_id, c.card_id
FROM gold.fact_transactions f
LEFT JOIN gold.dim_cards c ON f.card_key = c.card_key
WHERE c.card_key IS NULL;


--==========================================================
--Check for Orphaned Dimension Rows
--==========================================================
--Users not used in any transaction
SELECT u.user_id
FROM gold.dim_users u
LEFT JOIN gold.fact_transactions f ON u.user_key = f.user_key
WHERE f.user_key IS NULL;

--Cards not used in any transaction
SELECT c.card_id
FROM gold.dim_cards c
LEFT JOIN gold.fact_transactions f ON c.card_key = f.card_key
WHERE f.card_key IS NULL;


--===========================================================
--Check Data Consistency Across Dimensions
--===========================================================
--Card belongs to the same user as the transaction
--If rows appear → invalid card–user relationship

SELECT f.transaction_id, u.user_id AS fact_client,
       c.client_id AS card_client
FROM gold.dim_cards c
JOIN  gold.fact_transactions f ON f.card_key = c.card_key 
LEFT JOIN [gold].[dim_users] u ON  u.[user_key]=f.[user_key]
WHERE u.user_id <> c.client_id;

--===========================================================
--Check Date Validity in Fact Table
--===========================================================
SELECT transaction_id, transaction_date
FROM gold.fact_transactions
WHERE transaction_date IS NULL
   OR transaction_date > GETDATE()
   OR transaction_date < '1900-01-01';


--===========================================================
--Check Amount Accuracy
--===========================================================
SELECT transaction_id, amount
FROM gold.fact_transactions
WHERE amount <= 0;

--===========================================================
--Check Categorical Standardization
--===========================================================
--These should return clean, standardized values

SELECT DISTINCT use_chip FROM gold.fact_transactions;
SELECT DISTINCT gender FROM gold.dim_users;
SELECT DISTINCT has_chip FROM gold.dim_cards;





