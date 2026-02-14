/*
===================================
Create Database and Schemas
===================================
Script Purpose:
This script creates a new database named 'DataWarehouse' after checking if it already exists.
If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas within the database: 'bronze', 'silver', and 'gold*.
WARNING:
Running this script will drop the entire 'DataWarehouse' database if it exists.
All data in the database will be permanently deleted. Proceed with caution and ensure you have proper backups before running this script.
*/

Use master;
GO
  
-- Check if database exists
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'Banking Transactions')
BEGIN
    ALTER DATABASE [Banking Transactions] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [Banking Transactions];
END;
GO

-- Create Database
CREATE DATABASE [Banking Transactions];
GO

-- Use Database
USE [Banking Transactions];
GO

-- Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
