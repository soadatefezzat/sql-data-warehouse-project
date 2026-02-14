/*
===========================================
DDL script : create silver tables
===========================================
script purpose : 
this script creates tables in the 'silver' schema , droppig existing tables if they already exist.
run this script to re-define the DDL sructure of 'bronze' tables.
============================================
*/


USE [Banking Transactions];
GO

-- Drop table if exists
IF OBJECT_ID('silver.Banking_Transactions', 'U') IS NOT NULL
BEGIN
    DROP TABLE silver.Banking_Transactions;
END
GO

-- Create silver Table
CREATE TABLE silver.transactions_data (
    transaction_id INT PRIMARY KEY,
    client_id INT NULL,
    card_id INT NULL,
    transaction_date DATETIME2 NULL,
    merchant_id INT NULL,
    merchant_city VARCHAR(50) NULL,
    merchant_state VARCHAR(50) NULL,
    amount FLOAT NULL,
    use_chip VARCHAR(50) NULL,
    zip INT NULL,
    mcc INT NULL,
    errors VARCHAR(50) NULL
);

CREATE TABLE silver.users_data (
    user_id INT PRIMARY KEY,
    current_age INT NULL,
    retirement_age INT NULL,
    birth_year INT NULL,
    birth_month INT NULL,
    gender VARCHAR(50) NULL,
    address VARCHAR(50) NULL,
    latitude FLOAT NULL,
    longitude FLOAT NULL,
    per_capita_income INT NULL,
    yearly_income INT NULL,
    total_dept INT NULL,
    credit_score INT NULL,
    num_credit_cards INT NULL
);

CREATE TABLE silver.cards_data (
    card_id INT PRIMARY KEY,
    client_id INT NULL ,
    card_type VARCHAR(50) NULL,
    card_brand VARCHAR(50) NULL,
    card_number BIGINT NULL,
    expires DATE NULL,
    cvv INT NULL,
    has_chip VARCHAR(50) NULL,
    num_cards_issued INT NULL,
    credit_limit FLOAT NULL,
    acct_open_date DATE NULL,
    year_bin_last_changed INT NULL,
    card_on_dark_web VARCHAR(50) NULL,
    
);

SELECT COUNT([transaction_date]) FROM silver.transactions_data

