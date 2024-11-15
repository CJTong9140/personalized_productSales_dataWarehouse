-- ***************************************************
-- Name:    CJ Jingren Tong
-- ID:      152464194
-- Date:    October 24th, 2023
-- Purpose: ETL Application
--
-- Stored Procedure Files: 
-- *** check_birthYear_before_insert.sql
-- *** check_year_before_insert.sql
-- *** check_range_before_insert.sql
-- ***************************************************

-- **************************************************************
-- *** Ontario Baby Names 1917 - 2019 (Include Male & Female) *** 
-- **************************************************************

DROP TABLE st_babyNames; 
DROP TABLE babyNames; 

-- Create staging table 
CREATE TABLE st_babyNames (
    "Year"      INTEGER,
    "Name"      VARCHAR(15),
    "Frequency" INTEGER,
    "Gender"    VARCHAR(15)
);

-- Ingest all the data from .csv file to staging table
LOAD FROM '\\Mac\Home\Desktop\Portfolio\personalized_productSales_dataWarehouse\StaticCaforms\ontario_baby_names.csv' OF DEL
MODIFIED BY COLDEL,
METHOD P (1, 2, 3, 4) 
INSERT INTO st_babyNames ("Year", "Name", "Frequency", "Gender")

-- Check if any field that should not be null is null 
SELECT * FROM st_babyNames WHERE "Year" IS NULL; 
SELECT * FROM st_babyNames WHERE "Name" IS NULL; 
SELECT * FROM st_babyNames WHERE "Frequency" IS NULL; 
SELECT * FROM st_babyNames WHERE "Gender" IS NULL; 

-- Data Cleansing 
UPDATE st_babyNames
SET
    "Name" = INITCAP("Name"),
    "Gender" = INITCAP("Gender");

DELETE FROM st_babyNames 
    WHERE "Name" IS NULL OR "Frequency" IS NULL OR "Gender" IS NULL OR "Year" IS NULL; 

-- All baby names information are between year 1917 to 2019 
-- Female baby names csv file contain some records from 1913 to 1916.
-- To ensure consistency in analysis, particularly when comparing data across genders
DELETE FROM st_babyNames WHERE "Year" < 1917; 

COMMIT; 

-- Create Final table
CREATE TABLE babyNames (
    babyName_id INTEGER NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY, 
    -- "Birth Year" is being checked with trigger while insertion later on
    "Birth Year" INTEGER NOT NULL, 
    "First Name" VARCHAR(15) NOT NULL,
    "Frequency" INTEGER CHECK ("Frequency" >= 0), 
    "Gender" VARCHAR(15) CHECK ("Gender" in ('Male', 'Female'))
);

-- Run the trigger script to check "Birth Year" automatically before being inserted. 
-- db2 -tsvf \\<path>\check_birthYear_before_insert.sql > \\<path>\check_birthYear_before_insert.out

-- Move over the cleansed data from staging table to final table
INSERT INTO babyNames ("Birth Year", "First Name", "Frequency", "Gender") 
    SELECT "Year", "Name", "Frequency", "Gender" FROM st_babyNames;
    
-- Test the trigger
INSERT INTO babyNames ("Birth Year", "First Name", "Frequency", "Gender") VALUES (3000, 'Test', 10, 'Female'); 

-- Sample data from final table: babyNames 
SELECT * FROM babyNames FETCH FIRST 30 ROWS ONLY; 

-- Staging table row count
SELECT COUNT(*) FROM st_babyNames; 
-- Final table row count
SELECT COUNT(*) FROM babyNames; 


-- **************************************************************
-- ************ Ontario City Population 2002 - 2022 *************
-- **************************************************************

DROP TABLE st_population; 
DROP TABLE population; 

-- Create staging table
CREATE TABLE st_population (
yearRecorded INTEGER, 
city VARCHAR(30), 
population VARCHAR(10),
city_description VARCHAR(45) DEFAULT NULL
); 

-- Ingest all the data from .csv file to staging table
LOAD FROM '\\Mac\Home\Desktop\Portfolio\personalized_productSales_dataWarehouse\StaticCaforms\ontario_city_population.csv' OF DEL
MODIFIED BY COLDEL,
METHOD P (1, 2, 3, 4) 
INSERT INTO st_population (yearRecorded, city, population, city_description)

-- Check if any field that should not be null is null 
SELECT * FROM st_population WHERE yearRecorded IS NULL; 
SELECT * FROM st_population WHERE city IS NULL; 
SELECT * FROM st_population WHERE population IS NULL; 

-- Data Cleansing 
UPDATE st_population SET population = REPLACE(population, ',', '');

COMMIT; 

-- Create Final table
CREATE TABLE population (
    city_id INTEGER NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY, 
     -- "Year Recorded" is being checked with trigger automatically during insertion later on
    "Year Recorded" INTEGER NOT NULL,
    "City" VARCHAR(30) NOT NULL,
    "Population" INTEGER NOT NULL CHECK ("Population" > 0), 
    "City Description" VARCHAR(45) DEFAULT NULL
);

-- Run the trigger script to check "Year" automatically before being inserted. 
-- db2 -tsvf \\<path>\check_year_before_insert.sql > \\<path>\check_year_before_insert.out

-- Move over the cleansed data from staging table to final table
INSERT INTO population ("Year Recorded", "City", "Population", "City Description") 
SELECT yearRecorded, city, CAST(population AS INTEGER), city_description FROM st_population;

-- Test the trigger
INSERT INTO population ("Year Recorded", "City", "Population") VALUES (3000, 'Test', 3000); 
COMMIT; 

-- Sample data from final table: Population 
SELECT * FROM population FETCH FIRST 30 ROWS ONLY; 

-- Staging table row count
SELECT COUNT(*) FROM st_population; 
-- Final table row count
SELECT COUNT(*) FROM population; 

-- **************************************************************
-- ******* Ontario Life Expectancy 2005/2007 - 2014/2016 ********
-- **************************************************************
DROP TABLE st_lifeExpectancy; 
DROP TABLE lifeExpectancy; 

-- Create staging table
CREATE TABLE st_lifeExpectancy (
    geographicRegion VARCHAR(80),
    gender VARCHAR(15), 
    referencePeriod CHAR(12), 
    lifeExpectancy DECIMAL(4, 1)
);

-- Ingest all the data from .csv file to staging table
LOAD FROM '\\Mac\Home\Desktop\Portfolio\personalized_productSales_dataWarehouse\StaticCaforms\ontario_life_expectancy.csv' OF DEL
MODIFIED BY COLDEL,
METHOD P (1, 2, 3, 4) 
INSERT INTO st_lifeExpectancy (geographicRegion, gender, referencePeriod, lifeExpectancy)

-- Check if any field that should not be null is null 
SELECT * FROM st_lifeExpectancy WHERE geographicRegion IS NULL; 
SELECT * FROM st_lifeExpectancy WHERE gender IS NULL; 
SELECT * FROM st_lifeExpectancy WHERE referencePeriod IS NULL; 
SELECT * FROM st_lifeExpectancy WHERE lifeExpectancy IS NULL; 

-- Data Cleansing 
UPDATE st_lifeExpectancy
SET
    gender = INITCAP(gender);
-- After checking output from load query and above output, no need for more data cleansing
-- Reference Period will be split into "Period Start Year" and "Period End Year" while insertion

COMMIT; 

-- Create Final table
CREATE TABLE lifeExpectancy ( 
    region_id INTEGER NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    "Geographic Region" VARCHAR(80) NOT NULL,
    "Gender" VARCHAR(15) NOT NULL CHECK ( "Gender" IN ( 'Males', 'Females' ) ),
    -- "Period Start Year" value is being checked in the trigger automatically before insertion
    "Period Start Year" INTEGER NOT NULL, 
    -- "Period End Year" value is being checked in the trigger automatically before insertion
    "Period End Year" INTEGER NOT NULL, 
    "Life Expectancy" DECIMAL(4, 1) NOT NULL CHECK ("Life Expectancy" >= 0.0) 
);

-- Run the trigger script to check "Period Start Year" and "Period End Year" automatically before being inserted. 
-- db2 -tsvf \\<path>\check_range_before_insert.sql > \\<path>\check_range_before_insert.out

-- Move over the cleansed data from staging table to final table
INSERT INTO lifeExpectancy ("Geographic Region", "Gender", "Period Start Year", "Period End Year", "Life Expectancy")
SELECT geographicRegion,
       gender,
       CAST(SUBSTRING(referencePeriod, 1, POSITION(' to ' IN referencePeriod) - 1) AS INTEGER),
       CAST(SUBSTRING(referencePeriod, POSITION(' to ' IN referencePeriod) + 4) AS INTEGER),
       lifeExpectancy
FROM st_lifeExpectancy;

-- Test the constraint
INSERT INTO lifeExpectancy ("Geographic Region", "Gender", "Period Start Year", "Period End Year", "Life Expectancy")
VALUES ('TESTING CONSTRAINT', 'None', 2001, 2007, 78);

-- Test the trigger
INSERT INTO lifeExpectancy ("Geographic Region", "Gender", "Period Start Year", "Period End Year", "Life Expectancy")
VALUES ('TESTING TRIGGER', 'Females', 2030, 2032, 78);

INSERT INTO lifeExpectancy ("Geographic Region", "Gender", "Period Start Year", "Period End Year", "Life Expectancy") 
VALUES ('TESTING TRIGGER', 'Females', 0, -1, 78);

INSERT INTO lifeExpectancy ("Geographic Region", "Gender", "Period Start Year", "Period End Year", "Life Expectancy") 
VALUES ('TESTING TRIGGER', 'Females', 2017, 2007, 78);

COMMIT; 

-- Sample data from final table: lifeExpectancy 
SELECT * FROM lifeExpectancy FETCH FIRST 30 ROWS ONLY; 

-- Staging table row count
SELECT COUNT(*) FROM st_lifeExpectancy; 
-- Final table row count
SELECT COUNT(*) FROM lifeExpectancy; 