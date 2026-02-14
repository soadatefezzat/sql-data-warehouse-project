/*
==============================================================================================
Quality Checks
==============================================================================================
Script Purpose:
This script performs various quality checks for data consistency, accuracy, and standardization across the 'silver' schema. It includes checks for:
- Null or duplicate primary keys.
- Unwanted spaces in string fields.
- Data standardization and consistency.
- Invalid date ranges and orders.
- Data consistency between related fields.
Usage Notes:
- Run these checks after data loading Silver Layer.
- Investigate and resolve any discrepancies found during the checks.
================================================================================================
*/

--===============================================================================================
--Check for duplicate or missing IDs
--===============================================================================================
SELECT card_id, COUNT(*) AS c
FROM silver.cards_data
GROUP BY card_id
HAVING COUNT(*) > 1 OR card_id IS NULL;

--===============================================================================================
--Check standardized chip flag
--===============================================================================================
SELECT DISTINCT 
    CASE 
        WHEN LOWER(has_chip) = 'yes' THEN 'Yes'
        WHEN LOWER(has_chip) = 'no'  THEN 'No'
        ELSE 'Unknown'
    END AS has_chip_standard
FROM silver.cards_data;

--===============================================================================================
--Check standardized dark web flag
--===============================================================================================
SELECT DISTINCT 
    CASE 
        WHEN LOWER(card_on_dark_web) = 'yes' THEN 'Yes'
        WHEN LOWER(card_on_dark_web) = 'no'  THEN 'No'
        ELSE 'Unknown'
    END AS dark_web_flag
FROM silver.cards_data;

--===============================================================================================
--Check for duplicate or missing transaction IDs
--===============================================================================================
SELECT transaction_id, COUNT(*) AS c
FROM silver.transactions_data
GROUP BY transaction_id
HAVING COUNT(*) > 1 OR transaction_id IS NULL;

--===============================================================================================
--Check for invalid amounts (negative or zero)
--it's not removed 
--===============================================================================================
SELECT transaction_id, amount
FROM silver.transactions_data
WHERE amount <= 0;

--===============================================================================================
--Check for duplicate or missing user IDs
--===============================================================================================
SELECT user_id, COUNT(*) AS c
FROM silver.users_data
GROUP BY user_id
HAVING COUNT(*) > 1 OR user_id IS NULL;

--===============================================================================================
--Check standardized gender values
--===============================================================================================
SELECT DISTINCT 
    CASE 
        WHEN LOWER(gender) IN ('m','male') THEN 'Male'
        WHEN LOWER(gender) IN ('f','female') THEN 'Female'
        ELSE 'Unknown'
    END AS gender_standard
FROM silver.users_data;
--===============================================================================================
-- Detect leading/trailing spaces in text fields
--===============================================================================================
SELECT card_id, card_type
FROM silver.cards_data
WHERE card_type LIKE ' %' OR card_type LIKE '% ';

SELECT user_id, gender
FROM silver.users_data
WHERE gender LIKE ' %' OR gender LIKE '% ';
--================================================================================================
-- Expired cards used after expiry
--not removed because the dataset is old so it's normal that they are expired
--================================================================================================
SELECT card_id, expires
FROM silver.cards_data
WHERE TRY_CONVERT(DATE, expires) < GETDATE();
--================================================================================================
-- Account open date after expiry (invalid)
--================================================================================================
SELECT card_id, acct_open_date, expires
FROM silver.cards_data
WHERE TRY_CONVERT(DATE, acct_open_date) > TRY_CONVERT(DATE, expires);
--================================================================================================
-- Debt-to-income ratio check
--================================================================================================
SELECT user_id, total_dept, yearly_income,
       CAST(total_dept AS FLOAT) / NULLIF(yearly_income,0) AS dti_ratio
FROM silver.users_data
WHERE yearly_income <= 0 OR total_dept < 0;
--================================================================================================
-- Credit limit vs number of cards issued
--================================================================================================
SELECT card_id, credit_limit, num_cards_issued
FROM silver.cards_data
WHERE credit_limit < 0 OR num_cards_issued < 0;


