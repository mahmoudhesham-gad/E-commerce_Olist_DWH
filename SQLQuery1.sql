SELECT TOP (1000) [customer_sk]
      ,[customer_bk]
      ,[customer_unique_id]
      ,[customer_zip_code_prefix]
      ,[customer_city]
      ,[customer_state]
      ,[valid_from]
      ,[valid_to]
      ,[is_current]
  FROM [Olist_DWH].[dbo].[Dim_Customer]

  ALTER TABLE Dim_Customer
DROP COLUMN 
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    valid_from,
    valid_to,
    is_current;

DROP DATABASE IF EXISTS Olist_Stage;
GO

CREATE DATABASE Olist_Stage;
GO

USE Olist_Stage;
GO

CREATE SCHEMA STG;
GO

CREATE TABLE STG.Customer
(
    customer_id               NVARCHAR(50),
    customer_unique_id        NVARCHAR(50),
    customer_zip_code_prefix  NVARCHAR(50),
    customer_city             NVARCHAR(MAX),
    customer_state            NVARCHAR(50),

    src_update_date           DATETIME,
    create_timestamp          DATETIME

);

ALTER TABLE STG.Customer
ALTER COLUMN customer_city  NVARCHAR(MAX);

CREATE TABLE STG.etl_watermark
(
    table_name         VARCHAR(50),
    last_extract_date  DATETIME
);

INSERT INTO STG.etl_watermark
VALUES ('Customer', '1994-01-01');

UPDATE STG.etl_watermark
SET last_extract_date = '1949-01-01'
WHERE table_name = 'Customer';

SELECT *
FROM Olist_Source_OLTP.dbo.olist_customers_dataset
WHERE last_update >
(
    SELECT last_extract_date
    FROM STG.etl_watermark
    WHERE table_name = 'Customer'
);

ALTER TABLE [Olist_Source_OLTP].[dbo].[olist_customers_dataset]
ADD last_update DATETIME NULL;

UPDATE [Olist_Source_OLTP].[dbo].[olist_customers_dataset]
SET last_update = '1950-01-01'
WHERE last_update IS NULL;

ALTER TABLE [Olist_Source_OLTP].[dbo].[olist_geolocation_dataset]
ADD last_update DATETIME NULL;

UPDATE [Olist_Source_OLTP].[dbo].[olist_geolocation_dataset]
SET last_update = '1950-01-01'
WHERE last_update IS NULL;

CREATE TABLE STG.Geolocation
(
    geolocation_zip_code_prefix INT,
    geolocation_lat            FLOAT,
    geolocation_lng            FLOAT,
    geolocation_city           NVARCHAR(MAX),
    geolocation_state          NVARCHAR(50),

    last_update                DATETIME DEFAULT GETDATE(),
    create_timestamp           DATETIME DEFAULT GETDATE()
);

ALTER TABLE [Olist_DWH].[dbo].[Dim_Location]
ALTER COLUMN city  NVARCHAR(MAX);

INSERT INTO STG.etl_watermark (table_name, last_extract_date)
VALUES ('Geolocation', '1949-01-01');