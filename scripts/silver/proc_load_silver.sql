/*
Stored Procedure: Load Silver Layer (Bronze -› Silver)
Script Purpose:
This stored procedure performs the ETL (Extract, Transform, Load) process to populate the 'silver' schema tables from the 'bronze schema.
Actions Performed:
- Truncates Silver tables.
- Inserts transformed and cleansed data from Bronze into Silver tables.
Parameters:
None.
This stored procedure does not accept any parameters or return any values.
Usage Example:
EXEC Silver. load_silver;
*/


USE [Banking Transactions];
GO

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN TRY
    DECLARE @batch_start_time DATETIME2,
            @batch_end_time   DATETIME2,
            @step_start_time  DATETIME2,
            @step_end_time    DATETIME2;

    SET @batch_start_time = GETDATE();

    -- Load Cards
    SET @step_start_time = GETDATE();
    TRUNCATE TABLE silver.cards_data;

    INSERT INTO silver.cards_data (
        card_id, client_id, card_type, card_brand, card_number,
        cvv, has_chip, num_cards_issued, credit_limit,
        year_bin_last_changed, card_on_dark_web, expires, acct_open_date
    )
    SELECT 
        card_id, client_id, card_type, card_brand, card_number,
        cvv, has_chip, num_cards_issued, credit_limit,
        year_bin_last_changed, card_on_dark_web, [[expires]]], [[acct_open_date]]]
    FROM bronze.cards_data;

    SET @step_end_time = GETDATE();
    PRINT '>> Cards load duration: ' + CAST(DATEDIFF(SECOND, @step_start_time, @step_end_time) AS NVARCHAR) + ' seconds';
    PRINT '>>---------------';

    -- Load Users
    SET @step_start_time = GETDATE();
    TRUNCATE TABLE silver.users_data;

    INSERT INTO silver.users_data (
        user_id, current_age, retirement_age, birth_year, birth_month,
        gender, address, latitude, longitude, per_capita_income,
        yearly_income, total_dept, credit_score, num_credit_cards
    )
    SELECT 
        user_id, current_age, retirement_age, birth_year, birth_month,
        gender, address, latitude, longitude, per_capita_income,
        yearly_income, total_dept, credit_score, num_credit_cards
    FROM bronze.users_data;

    SET @step_end_time = GETDATE();
    PRINT '>> Users load duration: ' + CAST(DATEDIFF(SECOND, @step_start_time, @step_end_time) AS NVARCHAR) + ' seconds';
    PRINT '>>---------------';

    -- Load Transactions
    SET @step_start_time = GETDATE();
    TRUNCATE TABLE silver.transactions_data;

    INSERT INTO silver.transactions_data (
        transaction_id, client_id, card_id, transaction_date, merchant_id,
        merchant_city, merchant_state, amount, use_chip, zip, mcc, errors
    )
    SELECT 
        transaction_id, client_id, card_id, transaction_date, merchant_id,
        merchant_city, merchant_state, amount, use_chip, zip, mcc, errors
    FROM bronze.transactions_data;

    SET @step_end_time = GETDATE();
    PRINT '>> Transactions load duration: ' + CAST(DATEDIFF(SECOND, @step_start_time, @step_end_time) AS NVARCHAR) + ' seconds';
    PRINT '>>---------------';

    -- Batch End
    SET @batch_end_time = GETDATE();
    PRINT '======================';
    PRINT 'Loading silver layer is completed';
    PRINT '  - Total load duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';

END TRY
BEGIN CATCH
    PRINT '========================';
    PRINT 'Error occurred during loading silver layer';
    PRINT 'Error message : ' + ERROR_MESSAGE();
    PRINT 'Error number  : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
    PRINT 'Error state   : ' + CAST(ERROR_STATE() AS NVARCHAR);
    PRINT '========================';
END CATCH;
GO
