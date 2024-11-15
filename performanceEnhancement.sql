-- ******************************************************************
-- Name:    CJ Jingren Tong
-- ID:      152464194
-- Date:    November 16th, 2023
-- Purpose: Performance Enhancements
-- ******************************************************************

-- ******************************************************************
-- ********    Partitioning: Multi-Dimensional Clustering    ********
-- ******************************************************************
-- Using MDC to store rows with the same values for fiscal_quarter_group and calender_year close together
-- on disk, which can improve the performance of queries that filter or join on these columns.
DROP TABLE sales_fact_mdc;

CREATE TABLE sales_fact_mdc (
    sales_fact_key                INTEGER NOT NULL,
    transaction_id                CHAR(6) NOT NULL,
    store_id                      INTEGER NOT NULL,
    date_key                      INTEGER,
    employee_unique_key           INTEGER NOT NULL,
    customer_id                   INTEGER NOT NULL,
    item_scan_timestamp           TIMESTAMP NOT NULL,
    product_id                    INTEGER NOT NULL,
    ageGroup_key                  INTEGER,
    payment_type_key              CHAR(4) NOT NULL,
    promcamp_key                  INTEGER DEFAULT NULL,
    fiscal_quarter_group          CHAR(2),
    calender_year                 INTEGER,
    calender_month                INTEGER,
    calender_date                 INTEGER,
    customer_gender               VARCHAR(6),
    product_name                  VARCHAR(45),
    ageGroup_name                 VARCHAR(20),
    product_list_price            DECIMAL(10, 2),
    customer_fname                VARCHAR(25),
    customer_lname                VARCHAR(25),
    store_specification           VARCHAR(5),
    store_name                    VARCHAR(50),
    payment_type                  VARCHAR(15),
    employee_name                 VARCHAR(60),
    sale_quantity                 INTEGER NOT NULL,
    sale_revenue                  DECIMAL(12, 2),
    sale_profit                   DECIMAL(10, 2),
    tax_dollar_amount             DECIMAL(10, 2),
    promotion_dollar_amount       DECIMAL(10, 2) DEFAULT 0.0,
    is_market_campaign            BOOLEAN DEFAULT FALSE,
    market_campaign_dollar_amount DECIMAL(10, 2) DEFAULT 0.0,
    PRIMARY KEY ( sales_fact_key ),
    CONSTRAINT sf_storeid_fk FOREIGN KEY ( store_id )
        REFERENCES stores ( store_id ),
    CONSTRAINT sf_datekey_fk FOREIGN KEY ( date_key )
        REFERENCES cal_dates ( date_key ),
    CONSTRAINT sf_employeeuniquekey_fk FOREIGN KEY ( employee_unique_key )
        REFERENCES employees ( employee_unique_key ),
    CONSTRAINT sf_customerid_fk FOREIGN KEY ( customer_id )
        REFERENCES customers ( customer_id ),
    CONSTRAINT sf_productid_fk FOREIGN KEY ( product_id )
        REFERENCES products ( product_id ),
    CONSTRAINT sf_ageGroup_fk FOREIGN KEY ( ageGroup_key )
        REFERENCES age_groups ( ageGroup_key ),
    CONSTRAINT sf_paymenttypekey_fk FOREIGN KEY ( payment_type_key )
        REFERENCES payments ( payment_type_key ),
    CONSTRAINT sf_promotionkey_fk FOREIGN KEY ( promcamp_key )
        REFERENCES promotions_n_campaign ( promcamp_key )
) ORGANIZE BY DIMENSIONS (fiscal_quarter_group, calender_year);

INSERT INTO sales_fact_mdc SELECT * FROM sales_fact;

-- Output
SELECT * FROM sales_fact_mdc;

SELECT COUNT(*) FROM sales_fact_mdc;

-- Test
CALL SYSPROC.SYSINSTALLOBJECTS('EXPLAIN', 'C', NULL, 'CJTONG');

EXPLAIN PLAN FOR
SELECT * FROM sales_fact_mdc WHERE fiscal_quarter_group = 'Q1' AND calender_year = 2023;

SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

EXPLAIN PLAN FOR
SELECT * FROM sales_fact WHERE fiscal_quarter_group = 'Q1' AND calender_year = 2023;

SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);


-- ******************************************************************
-- ********      Partitioning: Combining MDC with RP        *********
-- ******************************************************************
-- MDC: first layer of optimization, clustering data rows by dimension values.
-- Range Partitioning: Second layer of optimization, organizing these clusters into partitions based on value ranges.
-- By combining together, can provide a powerful optimization strategy for both the physical layout of individual rows 
-- and the broader organization of the table for a wide range of query types. 
DROP TABLE sales_fact_mdcWithRp;

CREATE TABLE sales_fact_mdcWithRp (
    sales_fact_key                INTEGER NOT NULL,
    transaction_id                CHAR(6) NOT NULL,
    store_id                      INTEGER NOT NULL,
    date_key                      INTEGER,
    employee_unique_key           INTEGER NOT NULL,
    customer_id                   INTEGER NOT NULL,
    item_scan_timestamp           TIMESTAMP NOT NULL,
    product_id                    INTEGER NOT NULL,
    ageGroup_key                  INTEGER,
    payment_type_key              CHAR(4) NOT NULL,
    promcamp_key                  INTEGER DEFAULT NULL,
    fiscal_quarter_group          CHAR(2),
    calender_year                 INTEGER,
    calender_month                INTEGER,
    calender_date                 INTEGER,
    customer_gender               VARCHAR(6),
    product_name                  VARCHAR(45),
    ageGroup_name                 VARCHAR(20),
    product_list_price            DECIMAL(10, 2),
    customer_fname                VARCHAR(25),
    customer_lname                VARCHAR(25),
    store_specification           VARCHAR(5),
    store_name                    VARCHAR(50),
    payment_type                  VARCHAR(15),
    employee_name                 VARCHAR(60),
    sale_quantity                 INTEGER NOT NULL,
    sale_revenue                  DECIMAL(12, 2),
    sale_profit                   DECIMAL(10, 2),
    tax_dollar_amount             DECIMAL(10, 2),
    promotion_dollar_amount       DECIMAL(10, 2) DEFAULT 0.0,
    is_market_campaign            BOOLEAN DEFAULT FALSE,
    market_campaign_dollar_amount DECIMAL(10, 2) DEFAULT 0.0,
    PRIMARY KEY ( sales_fact_key ),
    CONSTRAINT sf_storeid_fk FOREIGN KEY ( store_id )
        REFERENCES stores ( store_id ),
    CONSTRAINT sf_datekey_fk FOREIGN KEY ( date_key )
        REFERENCES cal_dates ( date_key ),
    CONSTRAINT sf_employeeuniquekey_fk FOREIGN KEY ( employee_unique_key )
        REFERENCES employees ( employee_unique_key ),
    CONSTRAINT sf_customerid_fk FOREIGN KEY ( customer_id )
        REFERENCES customers ( customer_id ),
    CONSTRAINT sf_productid_fk FOREIGN KEY ( product_id )
        REFERENCES products ( product_id ),
    CONSTRAINT sf_ageGroup_fk FOREIGN KEY ( ageGroup_key )
        REFERENCES age_groups ( ageGroup_key ),
    CONSTRAINT sf_paymenttypekey_fk FOREIGN KEY ( payment_type_key )
        REFERENCES payments ( payment_type_key ),
    CONSTRAINT sf_promotionkey_fk FOREIGN KEY ( promcamp_key )
        REFERENCES promotions_n_campaign ( promcamp_key )
) PARTITION BY RANGE (calender_year) (
    PARTITION y2021 STARTING (2021) INCLUSIVE ENDING (2022) EXCLUSIVE,
    PARTITION y2022 STARTING (2022) INCLUSIVE ENDING (2023) EXCLUSIVE,
    PARTITION y2023 STARTING (2023) INCLUSIVE ENDING (2024) EXCLUSIVE
)
ORGANIZE BY DIMENSIONS (calender_year, fiscal_quarter_group);

INSERT INTO sales_fact_mdcWithRp SELECT * FROM sales_fact;

-- Output
SELECT * FROM sales_fact_mdcWithRp;
SELECT * FROM sales_fact_mdcWithRp ORDER BY sales_fact_key;

SELECT COUNT(*) FROM sales_fact_mdcWithRp;

-- Test
EXPLAIN PLAN FOR
SELECT * FROM sales_fact_mdcWithRp WHERE fiscal_quarter_group = 'Q4' AND calender_year = 2023;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

EXPLAIN PLAN FOR
SELECT * FROM sales_fact_mdc WHERE fiscal_quarter_group = 'Q4' AND calender_year = 2023;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

EXPLAIN PLAN FOR
SELECT * FROM sales_fact WHERE fiscal_quarter_group = 'Q4' AND calender_year = 2023;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);


-- ******************************************************************
-- *************         Compression: Indexing          *************
-- ******************************************************************
-- Creating indexes on frequently queried columns can significantly speed up query retrieval execution.
-- Since business analytic queries often filter on combinations of fiscal_quarter_group, calender_year, alongside another 
-- dimension like store_id, product_id, ageGroup_key or employee_unique_key, composite indexes on these combinations would 
-- be beneficial.
DROP INDEX idx_fiscal_calendar;
DROP INDEX idx_fiscal_store;
DROP INDEX idx_fiscal_product;
DROP INDEX idx_fiscal_ageGroup;
DROP INDEX idx_fiscal_employee;

-- Before index being added, run test to check some business analytic performance without index being applied. 
EXPLAIN PLAN FOR
SELECT 
    fiscal_quarter_group, 
    calender_year,
    store_id, 
    store_name, 
    SUM(sale_revenue) AS total_sales_revenue
FROM 
    sales_fact
GROUP BY 
    fiscal_quarter_group,
    calender_year, 
    store_id, 
    store_name
ORDER BY 
    store_id,
    calender_year,
    fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

EXPLAIN PLAN FOR
SELECT 
    fiscal_quarter_group, 
    calender_year, 
    product_id, 
    product_name, 
    SUM(sale_quantity) AS total_sales_volume
FROM 
    sales_fact
GROUP BY 
    fiscal_quarter_group, 
    calender_year,
    product_id, 
    product_name
ORDER BY 
    product_id,
    calender_year,
    fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

EXPLAIN PLAN FOR
SELECT 
    fiscal_quarter_group, 
    calender_year,
    ageGroup_key, 
    ageGroup_name, 
    SUM(sale_profit) AS total_sales_profit
FROM 
    sales_fact
GROUP BY 
    fiscal_quarter_group, 
    calender_year,
    ageGroup_key, 
    ageGroup_name
ORDER BY 
    ageGroup_key, 
    calender_year,
    fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

EXPLAIN PLAN FOR
WITH RankedSaleEmps as (
    SELECT
        employee_unique_key, 
        employee_name,
        fiscal_quarter_group,
        calender_year,
        SUM(sale_revenue) as total_revenue,
        RANK() OVER (PARTITION BY fiscal_quarter_group, calender_year ORDER BY SUM(sale_revenue) DESC) as rankedSale
    FROM sales_fact
    GROUP BY employee_unique_key, employee_name, fiscal_quarter_group, calender_year
)
SELECT employee_name, fiscal_quarter_group, calender_year, total_revenue
FROM RankedSaleEmps
WHERE rankedSale = 1
ORDER BY calender_year, fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

-- Create (Composite) Indexes
CREATE INDEX idx_fiscal_calendar ON sales_fact (calender_year, fiscal_quarter_group);
CREATE INDEX idx_fiscal_store ON sales_fact (store_id, calender_year, fiscal_quarter_group);
CREATE INDEX idx_fiscal_product ON sales_fact (product_id, calender_year, fiscal_quarter_group);
CREATE INDEX idx_fiscal_ageGroup ON sales_fact (ageGroup_key, calender_year, fiscal_quarter_group);
CREATE INDEX idx_fiscal_employee ON sales_fact (employee_unique_key, calender_year, fiscal_quarter_group);

-- Test after indexes creations
SELECT INDNAME, TABNAME, UNIQUERULE, COLNAMES
FROM SYSCAT.INDEXES
WHERE TABNAME = 'SALES_FACT';

-- Make sure statistics updated so that the optimizer has the most current information
RUNSTATS ON TABLE CJTONG.sales_fact WITH DISTRIBUTION AND DETAILED INDEXES ALL;

EXPLAIN PLAN FOR
SELECT 
    fiscal_quarter_group, 
    calender_year,
    store_id, 
    store_name, 
    SUM(sale_revenue) AS total_sales_revenue
FROM 
    sales_fact
GROUP BY 
    fiscal_quarter_group,
    calender_year, 
    store_id, 
    store_name
ORDER BY 
    store_id,
    calender_year,
    fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

EXPLAIN PLAN FOR
SELECT 
    fiscal_quarter_group, 
    calender_year, 
    product_id, 
    product_name, 
    SUM(sale_quantity) AS total_sales_volume
FROM 
    sales_fact
GROUP BY 
    fiscal_quarter_group, 
    calender_year,
    product_id, 
    product_name
ORDER BY 
    product_id,
    calender_year,
    fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

EXPLAIN PLAN FOR
SELECT 
    fiscal_quarter_group, 
    calender_year,
    ageGroup_key, 
    ageGroup_name, 
    SUM(sale_profit) AS total_sales_profit
FROM 
    sales_fact
GROUP BY 
    fiscal_quarter_group, 
    calender_year,
    ageGroup_key, 
    ageGroup_name
ORDER BY 
    ageGroup_key, 
    calender_year,
    fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

EXPLAIN PLAN FOR
WITH RankedSaleEmps as (
    SELECT
        employee_unique_key, 
        employee_name,
        fiscal_quarter_group,
        calender_year,
        SUM(sale_revenue) as total_revenue,
        RANK() OVER (PARTITION BY fiscal_quarter_group, calender_year ORDER BY SUM(sale_revenue) DESC) as rankedSale
    FROM sales_fact
    GROUP BY employee_unique_key, employee_name, fiscal_quarter_group, calender_year
)
SELECT employee_name, fiscal_quarter_group, calender_year, total_revenue
FROM RankedSaleEmps
WHERE rankedSale = 1
ORDER BY calender_year, fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

-- *******************************************************************
-- ******      Data Optimization: Summary/Aggregate table       ******
-- *******************************************************************
-- Creating summary (aggregate) tables for frequently accessed aggregated data can drastically reduce query time.
-- Information for sale_quantity, sale_revenue, and sale_profit are often queried based on store, age group, product and employee, 
-- and they often being recorded yearly or by certain fiscal quarter group. 
-- Summary table for store
DROP TABLE store_sales_summary;

-- Before creating summary tables and indexes, test for performance prior to optimizations
EXPLAIN PLAN FOR 
SELECT  
    fiscal_quarter_group, 
    calender_year,  
    store_id, 
    store_name, 
    SUM(sale_quantity) AS total_sales_volume
FROM 
    sales_fact
GROUP BY 
    fiscal_quarter_group, 
    calender_year, 
    store_id, 
    store_name
ORDER BY 
    store_id,
    calender_year,
    fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

EXPLAIN PLAN FOR 
WITH StoreFiscalQuarters AS (
    SELECT 
        s.store_id, 
        s.store_specification, 
        s.store_name,
        c.fiscal_quarter_group,
        c.cal_year
    FROM 
        (SELECT DISTINCT store_id, store_specification, store_name FROM sales_fact) s
    CROSS JOIN 
        (SELECT DISTINCT fiscal_quarter_group, cal_year FROM cal_dates_with_fiscal) c
),
SalesWithQuarters AS (
    SELECT 
        sfq.store_id, 
        sfq.store_specification, 
        sfq.store_name,
        sfq.fiscal_quarter_group,
        sfq.cal_year,
        COALESCE(SUM(sf.sale_revenue), 0) AS total_revenue, 
        COALESCE(SUM(sf.sale_profit), 0) AS total_profit
    FROM 
        StoreFiscalQuarters sfq
    LEFT JOIN 
        sales_fact sf 
        ON sfq.store_id = sf.store_id 
        AND sfq.fiscal_quarter_group = sf.fiscal_quarter_group
        AND sfq.cal_year = sf.calender_year
    GROUP BY 
        sfq.store_id, 
        sfq.store_specification, 
        sfq.store_name,
        sfq.fiscal_quarter_group,
        sfq.cal_year
)
SELECT 
    sq.store_id, 
    sq.store_specification, 
    sq.store_name,
    sq.fiscal_quarter_group,
    sq.cal_year, 
    sq.total_revenue, 
    sq.total_profit,
    LAG(sq.total_revenue) OVER (PARTITION BY sq.store_id ORDER BY sq.cal_year, sq.fiscal_quarter_group) AS previous_quarter_revenue,
    LAG(sq.total_profit) OVER (PARTITION BY sq.store_id ORDER BY sq.cal_year, sq.fiscal_quarter_group) AS previous_quarter_profit,
    CASE 
        WHEN sq.total_revenue > COALESCE(LAG(sq.total_revenue) OVER (PARTITION BY sq.store_id ORDER BY sq.cal_year, sq.fiscal_quarter_group), 0) THEN 'Growth'
        WHEN sq.total_revenue < COALESCE(LAG(sq.total_revenue) OVER (PARTITION BY sq.store_id ORDER BY sq.cal_year, sq.fiscal_quarter_group), 0) THEN 'Decline'
        ELSE 'Stable'
    END AS storeRevenue_trend
FROM 
    SalesWithQuarters sq
ORDER BY 
    sq.store_id, 
    sq.cal_year,
    sq.fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

-- Following summary table that pre-aggregates revenue and profit by store, fiscal quarter, and calendar year. 
CREATE TABLE store_sales_summary (
    store_id INTEGER,
    store_specification VARCHAR(5),
    store_name VARCHAR(50),
    fiscal_quarter_group CHAR(2),
    calender_year INTEGER,
    total_sales_quantity INTEGER,
    total_sales_revenue DECIMAL(12, 2),
    total_sales_profit DECIMAL(12, 2)
);

-- Indexes on summary tables are often more effective than those on transactional tables due to the reduced row count and the focused nature of the data.
-- Create indexes on store_sales_summary for store_id, fiscal_quarter_group, and calender_year to optimize query performance.
CREATE INDEX idx_summary_fiscal_calendar ON store_sales_summary (calender_year, fiscal_quarter_group);
CREATE INDEX idx_summary_fiscal_store ON store_sales_summary (store_id, calender_year, fiscal_quarter_group);

-- Test after indexes creations
SELECT INDNAME, TABNAME, UNIQUERULE, COLNAMES
FROM SYSCAT.INDEXES
WHERE TABNAME = 'STORE_SALES_SUMMARY';

-- Make sure statistics updated so that the optimizer has the most current information
RUNSTATS ON TABLE CJTONG.store_sales_summary WITH DISTRIBUTION AND DETAILED INDEXES ALL;

-- Data insertion 
INSERT INTO store_sales_summary (
    store_id,
    store_specification,
    store_name,
    fiscal_quarter_group,
    calender_year,
    total_sales_quantity,
    total_sales_revenue,
    total_sales_profit
)
SELECT 
    store_id, 
    store_specification,
    store_name,
    fiscal_quarter_group, 
    calender_year,
    SUM(sale_quantity) AS total_quantity,
    SUM(sale_revenue) AS total_revenue,
    SUM(sale_profit) AS total_profit
FROM 
    sales_fact
GROUP BY 
    store_id, 
    store_specification,
    store_name,
    fiscal_quarter_group, 
    calender_year;

-- After creating or updating the summary table, use the RUNSTATS command to update the table's statistics, which helps the optimizer to choose the best 
-- execution plan for queries using this table.
RUNSTATS ON TABLE CJTONG.store_sales_summary WITH DISTRIBUTION AND DETAILED INDEXES ALL;

-- Output
SELECT * FROM store_sales_summary ORDER BY store_id, calender_year, fiscal_quarter_group;

-- Test
-- As we can see, all the queries that was being performed on sales_fact table can be performed on the aggregation table we have just created now.
-- All queries are noticeably less complex, also eliminating the need to join tables at situations. 
EXPLAIN PLAN FOR 
SELECT  
    fiscal_quarter_group, 
    calender_year,  
    store_id, 
    store_name, 
    total_sales_quantity
FROM 
    store_sales_summary
ORDER BY 
    store_id,
    calender_year,
    fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

EXPLAIN PLAN FOR 
WITH AllStoreQuarters AS (
    SELECT 
        s.store_id, 
        s.store_specification, 
        s.store_name,
        fqy.fiscal_quarter_group,
        fqy.cal_year
    FROM 
        (SELECT DISTINCT store_id, store_specification, store_name FROM store_sales_summary) s
    CROSS JOIN 
        (SELECT DISTINCT fiscal_quarter_group, cal_year FROM cal_dates_with_fiscal) fqy
),
SalesWithQuarters AS (
    SELECT 
        asq.store_id, 
        asq.store_specification, 
        asq.store_name,
        asq.fiscal_quarter_group,
        asq.cal_year,
        COALESCE(ss.total_sales_revenue, 0) AS total_revenue, 
        COALESCE(ss.total_sales_profit, 0) AS total_profit
    FROM 
        AllStoreQuarters asq
    LEFT JOIN store_sales_summary ss
        ON asq.store_id = ss.store_id 
        AND asq.fiscal_quarter_group = ss.fiscal_quarter_group
        AND asq.cal_year = ss.calender_year
)
SELECT 
    sqw.store_id, 
    sqw.store_specification, 
    sqw.store_name,
    sqw.fiscal_quarter_group,
    sqw.cal_year, 
    sqw.total_revenue, 
    sqw.total_profit,
    LAG(sqw.total_revenue) OVER (PARTITION BY sqw.store_id ORDER BY sqw.cal_year, sqw.fiscal_quarter_group) AS previous_quarter_revenue,
    LAG(sqw.total_profit) OVER (PARTITION BY sqw.store_id ORDER BY sqw.cal_year, sqw.fiscal_quarter_group) AS previous_quarter_profit,
    CASE 
        WHEN sqw.total_revenue > COALESCE(LAG(sqw.total_revenue) OVER (PARTITION BY sqw.store_id ORDER BY sqw.cal_year, sqw.fiscal_quarter_group), 0) THEN 'Growth'
        WHEN sqw.total_revenue < COALESCE(LAG(sqw.total_revenue) OVER (PARTITION BY sqw.store_id ORDER BY sqw.cal_year, sqw.fiscal_quarter_group), 0) THEN 'Decline'
        ELSE 'Stable'
    END AS storeRevenue_trend
FROM 
    SalesWithQuarters sqw
ORDER BY 
    sqw.store_id, 
    sqw.cal_year,
    sqw.fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

-- Summary table for Product 
DROP TABLE product_sales_summary;

-- Before creating summary tables and indexes, test for performance prior to optimizations
EXPLAIN PLAN FOR 
SELECT 
    fiscal_quarter_group, 
    calender_year, 
    product_id, 
    product_name, 
    SUM(sale_quantity) AS total_sales_volume
FROM 
    sales_fact
GROUP BY 
    fiscal_quarter_group, 
    calender_year,
    product_id, 
    product_name
ORDER BY 
    product_id,
    calender_year,
    fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

EXPLAIN PLAN FOR 
WITH ProductFiscalQuarters AS (
    SELECT 
        s.product_id, 
        s.product_name,
        c.fiscal_quarter_group,
        c.cal_year
    FROM 
        (SELECT DISTINCT product_id, product_name FROM sales_fact) s
    CROSS JOIN 
        (SELECT DISTINCT fiscal_quarter_group, cal_year FROM cal_dates_with_fiscal) c
),
SalesWithQuarters AS (
    SELECT 
        pfq.product_id, 
        pfq.product_name,
        pfq.fiscal_quarter_group,
        pfq.cal_year,
        COALESCE(SUM(sf.sale_revenue), 0) AS total_revenue, 
        COALESCE(SUM(sf.sale_profit), 0) AS total_profit
    FROM 
        ProductFiscalQuarters pfq
    LEFT JOIN 
        sales_fact sf ON pfq.product_id = sf.product_id AND pfq.fiscal_quarter_group = sf.fiscal_quarter_group AND pfq.cal_year = sf.calender_year
    GROUP BY 
        pfq.product_id, 
        pfq.product_name,
        pfq.fiscal_quarter_group,
        pfq.cal_year
)
SELECT 
    sq.product_id, 
    sq.product_name,
    sq.fiscal_quarter_group,
    sq.cal_year,
    sq.total_revenue, 
    sq.total_profit,
    pq.total_revenue AS previous_quarter_revenue,
    pq.total_profit AS previous_quarter_profit,
    CASE 
        WHEN sq.total_revenue > pq.total_revenue THEN 'Growth'
        WHEN sq.total_revenue < pq.total_revenue THEN 'Decline'
        ELSE 'Stable'
    END AS productRevenue_trend
FROM 
    SalesWithQuarters sq
LEFT JOIN 
    SalesWithQuarters pq ON sq.product_id = pq.product_id 
    AND ((sq.cal_year = pq.cal_year AND CAST(SUBSTR(sq.fiscal_quarter_group, 2, 1) AS INT) = CAST(SUBSTR(pq.fiscal_quarter_group, 2, 1) AS INT) + 1) 
         OR (sq.cal_year = pq.cal_year + 1 AND sq.fiscal_quarter_group = 'Q1' AND pq.fiscal_quarter_group = 'Q4'))
ORDER BY 
    sq.product_id, 
    sq.cal_year,
    sq.fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

-- Following summary table that pre-aggregates quantity, revenue and profit by product, fiscal quarter, and calendar year. 
CREATE TABLE product_sales_summary (
    product_id INTEGER,
    product_name VARCHAR(45),
    product_list_price DECIMAL(10, 2),
    fiscal_quarter_group CHAR(2),
    calender_year INTEGER,
    total_sales_quantity INTEGER,
    total_sales_revenue DECIMAL(12, 2),
    total_sales_profit DECIMAL(12, 2)
);

-- Indexes on summary tables are often more effective than those on transactional tables due to the reduced row count and the focused nature of the data.
-- Create indexes on product_sales_summary for product_id, fiscal_quarter_group, and calender_year to optimize query performance.
CREATE INDEX idx_productSummary_fiscal_calendar ON product_sales_summary (calender_year, fiscal_quarter_group);
CREATE INDEX idx_productSummary_fiscal_product ON product_sales_summary (product_id, calender_year, fiscal_quarter_group);

-- Test after indexes creations
SELECT INDNAME, TABNAME, UNIQUERULE, COLNAMES
FROM SYSCAT.INDEXES
WHERE TABNAME = 'PRODUCT_SALES_SUMMARY';

-- Make sure statistics updated so that the optimizer has the most current information
RUNSTATS ON TABLE CJTONG.product_sales_summary WITH DISTRIBUTION AND DETAILED INDEXES ALL

-- Data insertion 
INSERT INTO product_sales_summary (
    product_id,
    product_name,
    product_list_price,
    fiscal_quarter_group,
    calender_year,
    total_sales_quantity,
    total_sales_revenue,
    total_sales_profit
)
SELECT 
    product_id,
    product_name,
    product_list_price,
    fiscal_quarter_group, 
    calender_year,
    SUM(sale_quantity) AS total_quantity,
    SUM(sale_revenue) AS total_revenue,
    SUM(sale_profit) AS total_profit
FROM 
    sales_fact
GROUP BY 
    product_id,
    product_name,
    product_list_price,
    fiscal_quarter_group, 
    calender_year;

-- After creating or updating the summary table, use the RUNSTATS command to update the table's statistics, which helps the optimizer to choose the best 
-- execution plan for queries using this table.
RUNSTATS ON TABLE CJTONG.product_sales_summary WITH DISTRIBUTION AND DETAILED INDEXES ALL;

-- Output
SELECT * FROM product_sales_summary ORDER BY product_id, calender_year, fiscal_quarter_group;

-- Test
-- As we can see, all the queries that was being performed on sales_fact table can be performed on the aggregation table we have just created now.
-- All queries are noticeably less complex. 
EXPLAIN PLAN FOR 
SELECT  
    fiscal_quarter_group, 
    calender_year,  
    product_id,
    product_name, 
    total_sales_quantity
FROM 
    product_sales_summary
ORDER BY 
    product_id,
    calender_year,
    fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

EXPLAIN PLAN FOR 
WITH AllProductQuarters AS (
    SELECT 
        p.product_id, 
        p.product_name, 
        fqy.fiscal_quarter_group,
        fqy.cal_year
    FROM 
        (SELECT DISTINCT product_id, product_name FROM product_sales_summary) p
    CROSS JOIN 
        (SELECT DISTINCT fiscal_quarter_group, cal_year FROM cal_dates_with_fiscal) fqy
),
SalesWithQuarters AS (
    SELECT 
        apq.product_id, 
        apq.product_name, 
        apq.fiscal_quarter_group,
        apq.cal_year,
        COALESCE(ps.total_sales_revenue, 0) AS total_revenue, 
        COALESCE(ps.total_sales_profit, 0) AS total_profit
    FROM 
        AllProductQuarters apq
    LEFT JOIN product_sales_summary ps
        ON apq.product_id = ps.product_id 
        AND apq.fiscal_quarter_group = ps.fiscal_quarter_group
        AND apq.cal_year = ps.calender_year
)
SELECT 
    sq.product_id, 
    sq.product_name,
    sq.fiscal_quarter_group,
    sq.cal_year, 
    sq.total_revenue, 
    sq.total_profit,
    pq.total_revenue AS previous_quarter_revenue,
    pq.total_profit AS previous_quarter_profit,
    CASE 
        WHEN sq.total_revenue > pq.total_revenue THEN 'Growth'
        WHEN sq.total_revenue < pq.total_revenue THEN 'Decline'
        ELSE 'Stable'
    END AS productRevenue_trend
FROM 
    SalesWithQuarters sq
LEFT JOIN 
    SalesWithQuarters pq ON sq.product_id = pq.product_id 
    AND ((sq.cal_year = pq.cal_year AND CAST(SUBSTR(sq.fiscal_quarter_group, 2, 1) AS INT) = CAST(SUBSTR(pq.fiscal_quarter_group, 2, 1) AS INT) + 1) 
         OR (sq.cal_year = pq.cal_year + 1 AND sq.fiscal_quarter_group = 'Q1' AND pq.fiscal_quarter_group = 'Q4'))
ORDER BY 
    sq.product_id, 
    sq.cal_year,
    sq.fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

-- Summary table for Age Group 
DROP TABLE ageGroup_sales_summary;

-- Before creating summary tables and indexes, test for performance prior to optimizations
EXPLAIN PLAN FOR 
SELECT 
    fiscal_quarter_group, 
    calender_year,
    ageGroup_key, 
    ageGroup_name, 
    SUM(sale_quantity) AS total_sales_volume
FROM 
    sales_fact
GROUP BY 
    fiscal_quarter_group, 
    calender_year,
    ageGroup_key, 
    ageGroup_name
ORDER BY 
    ageGroup_key, 
    calender_year,
    fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

-- Following summary table that pre-aggregates quantity, revenue and profit by age group, fiscal quarter, and calendar year. 
CREATE TABLE ageGroup_sales_summary (
    ageGroup_key INTEGER,
    ageGroup_name VARCHAR(20),
    fiscal_quarter_group CHAR(2),
    calender_year INTEGER,
    total_sales_quantity INTEGER,
    total_sales_revenue DECIMAL(12, 2),
    total_sales_profit DECIMAL(12, 2)
);

-- Indexes on summary tables are often more effective than those on transactional tables due to the reduced row count and the focused nature of the data.
-- Create indexes on ageGroup_sales_summary for ageGroup_key, fiscal_quarter_group, and calender_year to optimize query performance.
CREATE INDEX idx_ageGroupSummary_fiscal_calendar ON ageGroup_sales_summary (calender_year, fiscal_quarter_group);
CREATE INDEX idx_ageGroupSummary_fiscal_ageGroup ON ageGroup_sales_summary (ageGroup_key, calender_year, fiscal_quarter_group);

-- Test after indexes creations
SELECT INDNAME, TABNAME, UNIQUERULE, COLNAMES
FROM SYSCAT.INDEXES
WHERE TABNAME = 'AGEGROUP_SALES_SUMMARY';

-- Make sure statistics updated so that the optimizer has the most current information
RUNSTATS ON TABLE CJTONG.ageGroup_sales_summary WITH DISTRIBUTION AND DETAILED INDEXES ALL;

-- Data insertion 
INSERT INTO ageGroup_sales_summary (
    ageGroup_key,
    ageGroup_name,
    fiscal_quarter_group,
    calender_year,
    total_sales_quantity,
    total_sales_revenue,
    total_sales_profit
)
SELECT 
    ageGroup_key,
    ageGroup_name,
    fiscal_quarter_group, 
    calender_year,
    SUM(sale_quantity) AS total_quantity,
    SUM(sale_revenue) AS total_revenue,
    SUM(sale_profit) AS total_profit
FROM 
    sales_fact
GROUP BY 
    ageGroup_key,
    ageGroup_name,
    fiscal_quarter_group, 
    calender_year;

-- After creating or updating the summary table, use the RUNSTATS command to update the table's statistics, which helps the optimizer to choose the best 
-- execution plan for queries using this table.
RUNSTATS ON TABLE CJTONG.ageGroup_sales_summary WITH DISTRIBUTION AND DETAILED INDEXES ALL;

-- Output
SELECT * FROM ageGroup_sales_summary ORDER BY ageGroup_key, calender_year, fiscal_quarter_group;

-- Test
-- As we can see, all the queries that was being performed on sales_fact table can be performed on the aggregation table we have just created now.
-- All queries are noticeably less complex. 
EXPLAIN PLAN FOR 
SELECT  
    fiscal_quarter_group, 
    calender_year,  
    ageGroup_key,
    ageGroup_name, 
    total_sales_quantity
FROM 
    ageGroup_sales_summary
ORDER BY 
    ageGroup_key,
    calender_year,
    fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

-- ****************************************************************
-- **************     Simulate Temporary Tables      **************
-- ****************************************************************
-- For complex queries, particularly those involving multiple joins and aggregations, using temporary tables to store intermediate results can sometimes improve performance.
-- Materialized query tables can also pre-compute and store complex joins and aggregations, which can be very beneficial for speeding up complex queries that are run frequently. 
-- Based on above reasons, I want to use those methods to improve the performance for querying store trends and product trends
-- *** HOWEVER, Since I do not have permission for creating temporary tables, and I have also attempt by creating new tablespace, still do not have permission. 
-- *** And I have tried to create materialized query tables, but still have no permission to do so. 
CREATE BUFFERPOOL cjtSpace2_buffer SIZE 250 AUTOMATIC PAGESIZE 4096;

CREATE TABLESPACE cjtSpace2
MANAGED BY DATABASE
USING (FILE 'C:\DB2Tablespaces\Tablespaces' 262144)
EXTENTSIZE 16
BUFFERPOOL cjtSpace2_buffer;

DROP TABLESPACE cjtSpace2;
DROP BUFFERPOOL cjtSpace2_buffer;

-- Table contains Store Analysis of total revenue and total profit by fiscal quarter group in each year
-- *** Creating a regular table to hold intermediate results, and treating it conceptually as a "temporary" table in 
-- *** this scenerio, can be a pragmatic solution given the constraints I have faced with DB2 Community Edition.  
-- This approach, while not as elegant or efficient as using an actual temporary table, can be a practical workaround 
-- in environments with certain restrictions or limitations.
CREATE TABLE tempStoreFiscalQuarters (
    store_id INTEGER,
    store_specification VARCHAR(5),
    store_name VARCHAR(50),
    fiscal_quarter_group CHAR(2),
    cal_year INTEGER,
    total_revenue DECIMAL(15, 2),
    total_profit DECIMAL(15, 2)
);

-- Indexes on summary like tables are often more effective than those on transactional tables due to the reduced row count and the focused nature of the data.
-- Create indexes on tempStoreFiscalQuarters for store_id, fiscal_quarter_group, and cal_year to optimize query performance.
CREATE INDEX idx_tempStoreFiscalQuarters_fiscal_calendar ON tempStoreFiscalQuarters (cal_year, fiscal_quarter_group);
CREATE INDEX idx_tempStoreFiscalQuarters_fiscal_store ON tempStoreFiscalQuarters (store_id, cal_year, fiscal_quarter_group);

-- Test after indexes creations
SELECT INDNAME, TABNAME, UNIQUERULE, COLNAMES
FROM SYSCAT.INDEXES
WHERE TABNAME = 'TEMPSTOREFISCALQUARTERS';

-- Make sure statistics updated so that the optimizer has the most current information
RUNSTATS ON TABLE CJTONG.tempStoreFiscalQuarters WITH DISTRIBUTION AND DETAILED INDEXES ALL;

-- Data insertion 
INSERT INTO tempStoreFiscalQuarters
SELECT 
    s.store_id, 
    s.store_specification, 
    s.store_name,
    c.fiscal_quarter_group,
    c.cal_year,
    COALESCE(SUM(sf.sale_revenue), 0) AS total_revenue, 
    COALESCE(SUM(sf.sale_profit), 0) AS total_profit
FROM 
    (SELECT DISTINCT store_id, store_specification, store_name FROM sales_fact) s
    CROSS JOIN 
    (SELECT DISTINCT fiscal_quarter_group, cal_year FROM cal_dates_with_fiscal) c
    LEFT JOIN 
    sales_fact sf ON s.store_id = sf.store_id AND c.cal_year = sf.calender_year AND c.fiscal_quarter_group = sf.fiscal_quarter_group
GROUP BY 
    s.store_id, 
    s.store_specification, 
    s.store_name,
    c.cal_year,
    c.fiscal_quarter_group;

-- After creating or updating the summary table, use the RUNSTATS command to update the table's statistics, which helps the optimizer to choose the best 
-- execution plan for queries using this table.
RUNSTATS ON TABLE CJTONG.tempStoreFiscalQuarters WITH DISTRIBUTION AND DETAILED INDEXES ALL;

-- Use to test for querying from table tempStoreFiscalQuarters for growth trends for each store 
SELECT 
    store_id, 
    store_specification, 
    store_name,
    fiscal_quarter_group,
    cal_year, 
    total_revenue, 
    total_profit,
    LAG(total_revenue) OVER (PARTITION BY store_id ORDER BY cal_year, fiscal_quarter_group) AS previous_quarter_revenue,
    LAG(total_profit) OVER (PARTITION BY store_id ORDER BY cal_year, fiscal_quarter_group) AS previous_quarter_profit,
    CASE 
        WHEN total_revenue > COALESCE(LAG(total_revenue) OVER (PARTITION BY store_id ORDER BY cal_year, fiscal_quarter_group), 0) THEN 'Growth'
        WHEN total_revenue < COALESCE(LAG(total_revenue) OVER (PARTITION BY store_id ORDER BY cal_year, fiscal_quarter_group), 0) THEN 'Decline'
        ELSE 'Stable'
    END AS storeRevenue_trend
FROM 
    tempStoreFiscalQuarters
ORDER BY 
    store_id, 
    cal_year,
    fiscal_quarter_group;

-- Test original store trend query performance 
EXPLAIN PLAN FOR 
WITH StoreFiscalQuarters AS (
    SELECT 
        s.store_id, 
        s.store_specification, 
        s.store_name,
        c.fiscal_quarter_group,
        c.cal_year
    FROM 
        (SELECT DISTINCT store_id, store_specification, store_name FROM sales_fact) s
    CROSS JOIN 
        (SELECT DISTINCT fiscal_quarter_group, cal_year FROM cal_dates_with_fiscal) c
),
SalesWithQuarters AS (
    SELECT 
        sfq.store_id, 
        sfq.store_specification, 
        sfq.store_name,
        sfq.fiscal_quarter_group,
        sfq.cal_year,
        COALESCE(SUM(sf.sale_revenue), 0) AS total_revenue, 
        COALESCE(SUM(sf.sale_profit), 0) AS total_profit
    FROM 
        StoreFiscalQuarters sfq
    LEFT JOIN 
        sales_fact sf 
        ON sfq.store_id = sf.store_id 
        AND sfq.fiscal_quarter_group = sf.fiscal_quarter_group
        AND sfq.cal_year = sf.calender_year
    GROUP BY 
        sfq.store_id, 
        sfq.store_specification, 
        sfq.store_name,
        sfq.fiscal_quarter_group,
        sfq.cal_year
)
SELECT 
    sq.store_id, 
    sq.store_specification, 
    sq.store_name,
    sq.fiscal_quarter_group,
    sq.cal_year, 
    sq.total_revenue, 
    sq.total_profit,
    LAG(sq.total_revenue) OVER (PARTITION BY sq.store_id ORDER BY sq.cal_year, sq.fiscal_quarter_group) AS previous_quarter_revenue,
    LAG(sq.total_profit) OVER (PARTITION BY sq.store_id ORDER BY sq.cal_year, sq.fiscal_quarter_group) AS previous_quarter_profit,
    CASE 
        WHEN sq.total_revenue > COALESCE(LAG(sq.total_revenue) OVER (PARTITION BY sq.store_id ORDER BY sq.cal_year, sq.fiscal_quarter_group), 0) THEN 'Growth'
        WHEN sq.total_revenue < COALESCE(LAG(sq.total_revenue) OVER (PARTITION BY sq.store_id ORDER BY sq.cal_year, sq.fiscal_quarter_group), 0) THEN 'Decline'
        ELSE 'Stable'
    END AS storeRevenue_trend
FROM 
    SalesWithQuarters sq
ORDER BY 
    sq.store_id, 
    sq.cal_year,
    sq.fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

EXPLAIN PLAN FOR 
SELECT 
    store_id, 
    store_specification, 
    store_name,
    fiscal_quarter_group,
    cal_year, 
    total_revenue, 
    total_profit,
    LAG(total_revenue) OVER (PARTITION BY store_id ORDER BY cal_year, fiscal_quarter_group) AS previous_quarter_revenue,
    LAG(total_profit) OVER (PARTITION BY store_id ORDER BY cal_year, fiscal_quarter_group) AS previous_quarter_profit,
    CASE 
        WHEN total_revenue > COALESCE(LAG(total_revenue) OVER (PARTITION BY store_id ORDER BY cal_year, fiscal_quarter_group), 0) THEN 'Growth'
        WHEN total_revenue < COALESCE(LAG(total_revenue) OVER (PARTITION BY store_id ORDER BY cal_year, fiscal_quarter_group), 0) THEN 'Decline'
        ELSE 'Stable'
    END AS storeRevenue_trend
FROM 
    tempStoreFiscalQuarters
ORDER BY 
    store_id, 
    cal_year,
    fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

-- Table contains Product Analysis of total revenue and total profit by fiscal quarter group in each year
-- *** Creating a regular table to hold intermediate results, and treating it conceptually as a "temporary" table in 
-- *** this scenerio, can be a pragmatic solution given the constraints I have faced with DB2 Community Edition.  
-- This approach, while not as elegant or efficient as using an actual temporary table, can be a practical workaround 
-- in environments with certain restrictions or limitations.
CREATE TABLE tempProductFiscalQuarters (
    product_id INTEGER,
    product_name VARCHAR(45),
    fiscal_quarter_group CHAR(2),
    cal_year INTEGER,
    total_sales_revenue DECIMAL(12, 2),
    total_sales_profit DECIMAL(12, 2)
);

-- Indexes on summary like tables are often more effective than those on transactional tables due to the reduced row count and the focused nature of the data.
-- Create indexes on tempProductFiscalQuarters for product_id, fiscal_quarter_group, and cal_year to optimize query performance.
CREATE INDEX idx_tempProductFiscalQuarters_fiscal_calendar ON tempProductFiscalQuarters (cal_year, fiscal_quarter_group);
CREATE INDEX idx_tempProductFiscalQuarters_fiscal_store ON tempProductFiscalQuarters (product_id, cal_year, fiscal_quarter_group);

-- Test after indexes creations
SELECT INDNAME, TABNAME, UNIQUERULE, COLNAMES
FROM SYSCAT.INDEXES
WHERE TABNAME = 'TEMPPRODUCTFISCALQUARTERS';

-- Make sure statistics updated so that the optimizer has the most current information
RUNSTATS ON TABLE CJTONG.tempProductFiscalQuarters WITH DISTRIBUTION AND DETAILED INDEXES ALL;

-- Data insertion 
INSERT INTO tempProductFiscalQuarters
SELECT 
    s.product_id, 
    s.product_name,
    c.fiscal_quarter_group,
    c.cal_year,
    COALESCE(SUM(sf.sale_revenue), 0) AS total_sales_revenue, 
    COALESCE(SUM(sf.sale_profit), 0) AS total_sales_profit
FROM 
    (SELECT DISTINCT product_id, product_name FROM sales_fact) s
    CROSS JOIN 
    (SELECT DISTINCT fiscal_quarter_group, cal_year FROM cal_dates_with_fiscal) c
    LEFT JOIN 
    sales_fact sf ON s.product_id = sf.product_id AND c.cal_year = sf.calender_year AND c.fiscal_quarter_group = sf.fiscal_quarter_group
GROUP BY 
    s.product_id,
    s.product_name,
    c.cal_year,
    c.fiscal_quarter_group;

-- After creating or updating the summary table, use the RUNSTATS command to update the table's statistics, which helps the optimizer to choose the best 
-- execution plan for queries using this table.
RUNSTATS ON TABLE CJTONG.tempProductFiscalQuarters WITH DISTRIBUTION AND DETAILED INDEXES ALL;

-- Use to test for querying from table tempProductFiscalQuarters for growth trends for each store 
SELECT 
    product_id, 
    product_name, 
    fiscal_quarter_group,
    cal_year, 
    total_sales_revenue, 
    total_sales_profit,
    LAG(total_sales_revenue) OVER (PARTITION BY product_id ORDER BY cal_year, fiscal_quarter_group) AS previous_quarter_revenue,
    LAG(total_sales_profit) OVER (PARTITION BY product_id ORDER BY cal_year, fiscal_quarter_group) AS previous_quarter_profit,
    CASE 
        WHEN total_sales_revenue > COALESCE(LAG(total_sales_revenue) OVER (PARTITION BY product_id ORDER BY cal_year, fiscal_quarter_group), 0) THEN 'Growth'
        WHEN total_sales_revenue < COALESCE(LAG(total_sales_revenue) OVER (PARTITION BY product_id ORDER BY cal_year, fiscal_quarter_group), 0) THEN 'Decline'
        ELSE 'Stable'
    END AS productRevenue_trend
FROM 
    tempProductFiscalQuarters
ORDER BY 
    product_id, 
    cal_year,
    fiscal_quarter_group;

-- Test original store trend query performance 
EXPLAIN PLAN FOR 
WITH ProductFiscalQuarters AS (
    SELECT 
        s.product_id, 
        s.product_name,
        c.fiscal_quarter_group,
        c.cal_year
    FROM 
        (SELECT DISTINCT product_id, product_name FROM sales_fact) s
    CROSS JOIN 
        (SELECT DISTINCT fiscal_quarter_group, cal_year FROM cal_dates_with_fiscal) c
),
SalesWithQuarters AS (
    SELECT 
        pfq.product_id, 
        pfq.product_name,
        pfq.fiscal_quarter_group,
        pfq.cal_year,
        COALESCE(SUM(sf.sale_revenue), 0) AS total_revenue, 
        COALESCE(SUM(sf.sale_profit), 0) AS total_profit
    FROM 
        ProductFiscalQuarters pfq
    LEFT JOIN 
        sales_fact sf ON pfq.product_id = sf.product_id AND pfq.fiscal_quarter_group = sf.fiscal_quarter_group AND pfq.cal_year = sf.calender_year
    GROUP BY 
        pfq.product_id, 
        pfq.product_name,
        pfq.fiscal_quarter_group,
        pfq.cal_year
)
SELECT 
    sq.product_id, 
    sq.product_name,
    sq.fiscal_quarter_group,
    sq.cal_year,
    sq.total_revenue, 
    sq.total_profit,
    pq.total_revenue AS previous_quarter_revenue,
    pq.total_profit AS previous_quarter_profit,
    CASE 
        WHEN sq.total_revenue > pq.total_revenue THEN 'Growth'
        WHEN sq.total_revenue < pq.total_revenue THEN 'Decline'
        ELSE 'Stable'
    END AS productRevenue_trend
FROM 
    SalesWithQuarters sq
LEFT JOIN 
    SalesWithQuarters pq ON sq.product_id = pq.product_id 
    AND ((sq.cal_year = pq.cal_year AND CAST(SUBSTR(sq.fiscal_quarter_group, 2, 1) AS INT) = CAST(SUBSTR(pq.fiscal_quarter_group, 2, 1) AS INT) + 1) 
         OR (sq.cal_year = pq.cal_year + 1 AND sq.fiscal_quarter_group = 'Q1' AND pq.fiscal_quarter_group = 'Q4'))
ORDER BY 
    sq.product_id, 
    sq.cal_year,
    sq.fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

-- Test new store trend query performance through 
EXPLAIN PLAN FOR 
SELECT 
    product_id, 
    product_name, 
    fiscal_quarter_group,
    cal_year, 
    total_sales_revenue, 
    total_sales_profit,
    LAG(total_sales_revenue) OVER (PARTITION BY product_id ORDER BY cal_year, fiscal_quarter_group) AS previous_quarter_revenue,
    LAG(total_sales_profit) OVER (PARTITION BY product_id ORDER BY cal_year, fiscal_quarter_group) AS previous_quarter_profit,
    CASE 
        WHEN total_sales_revenue > COALESCE(LAG(total_sales_revenue) OVER (PARTITION BY product_id ORDER BY cal_year, fiscal_quarter_group), 0) THEN 'Growth'
        WHEN total_sales_revenue < COALESCE(LAG(total_sales_revenue) OVER (PARTITION BY product_id ORDER BY cal_year, fiscal_quarter_group), 0) THEN 'Decline'
        ELSE 'Stable'
    END AS productRevenue_trend
FROM 
    tempProductFiscalQuarters
ORDER BY 
    product_id, 
    cal_year,
    fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

-- Since want to simulate the behavior of a temporary table, and temporary tables are session-specific and will be dropped automatically at the end of the database session.
DROP TABLE tempStoreFiscalQuarters;
DROP TABLE tempProductFiscalQuarters;

-- ****************************************************************
-- ***************        Query Optimization        ***************
-- ****************************************************************
-- Product Trends 
-- Sales revenue is used for growth analysis as it directly reflects the market demand and sales performance of a product
-- Instead of joining SalesWithQuarters to itself to get the previous quarter's revenue and profit, consider using window functions like LAG. 
-- This can potentially simplify the query and improve performance.
-- Optimized query
WITH ProductFiscalQuarters AS (
    SELECT 
        s.product_id, 
        s.product_name,
        c.fiscal_quarter_group,
        c.cal_year
    FROM 
        (SELECT DISTINCT product_id, product_name FROM sales_fact) s
    CROSS JOIN 
        (SELECT DISTINCT fiscal_quarter_group, cal_year FROM cal_dates_with_fiscal) c
),
SalesWithQuarters AS (
    SELECT 
        pfq.product_id, 
        pfq.product_name,
        pfq.fiscal_quarter_group,
        pfq.cal_year,
        COALESCE(SUM(sf.sale_revenue), 0) AS total_revenue, 
        COALESCE(SUM(sf.sale_profit), 0) AS total_profit
    FROM 
        ProductFiscalQuarters pfq
    LEFT JOIN 
        sales_fact sf ON pfq.product_id = sf.product_id AND pfq.fiscal_quarter_group = sf.fiscal_quarter_group AND pfq.cal_year = sf.calender_year
    GROUP BY 
        pfq.product_id, 
        pfq.product_name,
        pfq.fiscal_quarter_group,
        pfq.cal_year
)
SELECT 
    product_id, 
    product_name, 
    fiscal_quarter_group,
    cal_year, 
    total_revenue, 
    total_profit,
    LAG(total_revenue) OVER (PARTITION BY product_id ORDER BY cal_year, fiscal_quarter_group) AS previous_quarter_revenue,
    LAG(total_profit) OVER (PARTITION BY product_id ORDER BY cal_year, fiscal_quarter_group) AS previous_quarter_profit,
    CASE 
        WHEN total_revenue > COALESCE(LAG(total_revenue) OVER (PARTITION BY product_id ORDER BY cal_year, fiscal_quarter_group), 0) THEN 'Growth'
        WHEN total_revenue < COALESCE(LAG(total_revenue) OVER (PARTITION BY product_id ORDER BY cal_year, fiscal_quarter_group), 0) THEN 'Decline'
        ELSE 'Stable'
    END AS productRevenue_trend
FROM 
    SalesWithQuarters
ORDER BY 
    product_id, 
    cal_year,
    fiscal_quarter_group;

-- Original query Performance 
EXPLAIN PLAN FOR 
WITH ProductFiscalQuarters AS (
    SELECT 
        s.product_id, 
        s.product_name,
        c.fiscal_quarter_group,
        c.cal_year
    FROM 
        (SELECT DISTINCT product_id, product_name FROM sales_fact) s
    CROSS JOIN 
        (SELECT DISTINCT fiscal_quarter_group, cal_year FROM cal_dates_with_fiscal) c
),
SalesWithQuarters AS (
    SELECT 
        pfq.product_id, 
        pfq.product_name,
        pfq.fiscal_quarter_group,
        pfq.cal_year,
        COALESCE(SUM(sf.sale_revenue), 0) AS total_revenue, 
        COALESCE(SUM(sf.sale_profit), 0) AS total_profit
    FROM 
        ProductFiscalQuarters pfq
    LEFT JOIN 
        sales_fact sf ON pfq.product_id = sf.product_id AND pfq.fiscal_quarter_group = sf.fiscal_quarter_group AND pfq.cal_year = sf.calender_year
    GROUP BY 
        pfq.product_id, 
        pfq.product_name,
        pfq.fiscal_quarter_group,
        pfq.cal_year
)
SELECT 
    sq.product_id, 
    sq.product_name,
    sq.fiscal_quarter_group,
    sq.cal_year,
    sq.total_revenue, 
    sq.total_profit,
    pq.total_revenue AS previous_quarter_revenue,
    pq.total_profit AS previous_quarter_profit,
    CASE 
        WHEN sq.total_revenue > pq.total_revenue THEN 'Growth'
        WHEN sq.total_revenue < pq.total_revenue THEN 'Decline'
        ELSE 'Stable'
    END AS productRevenue_trend
FROM 
    SalesWithQuarters sq
LEFT JOIN 
    SalesWithQuarters pq ON sq.product_id = pq.product_id 
    AND ((sq.cal_year = pq.cal_year AND CAST(SUBSTR(sq.fiscal_quarter_group, 2, 1) AS INT) = CAST(SUBSTR(pq.fiscal_quarter_group, 2, 1) AS INT) + 1) 
         OR (sq.cal_year = pq.cal_year + 1 AND sq.fiscal_quarter_group = 'Q1' AND pq.fiscal_quarter_group = 'Q4'))
ORDER BY 
    sq.product_id, 
    sq.cal_year,
    sq.fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);

EXPLAIN PLAN FOR 
WITH ProductFiscalQuarters AS (
    SELECT 
        s.product_id, 
        s.product_name,
        c.fiscal_quarter_group,
        c.cal_year
    FROM 
        (SELECT DISTINCT product_id, product_name FROM sales_fact) s
    CROSS JOIN 
        (SELECT DISTINCT fiscal_quarter_group, cal_year FROM cal_dates_with_fiscal) c
),
SalesWithQuarters AS (
    SELECT 
        pfq.product_id, 
        pfq.product_name,
        pfq.fiscal_quarter_group,
        pfq.cal_year,
        COALESCE(SUM(sf.sale_revenue), 0) AS total_revenue, 
        COALESCE(SUM(sf.sale_profit), 0) AS total_profit
    FROM 
        ProductFiscalQuarters pfq
    LEFT JOIN 
        sales_fact sf ON pfq.product_id = sf.product_id AND pfq.fiscal_quarter_group = sf.fiscal_quarter_group AND pfq.cal_year = sf.calender_year
    GROUP BY 
        pfq.product_id, 
        pfq.product_name,
        pfq.fiscal_quarter_group,
        pfq.cal_year
)
SELECT 
    product_id, 
    product_name, 
    fiscal_quarter_group,
    cal_year, 
    total_revenue, 
    total_profit,
    LAG(total_revenue) OVER (PARTITION BY product_id ORDER BY cal_year, fiscal_quarter_group) AS previous_quarter_revenue,
    LAG(total_profit) OVER (PARTITION BY product_id ORDER BY cal_year, fiscal_quarter_group) AS previous_quarter_profit,
    CASE 
        WHEN total_revenue > COALESCE(LAG(total_revenue) OVER (PARTITION BY product_id ORDER BY cal_year, fiscal_quarter_group), 0) THEN 'Growth'
        WHEN total_revenue < COALESCE(LAG(total_revenue) OVER (PARTITION BY product_id ORDER BY cal_year, fiscal_quarter_group), 0) THEN 'Decline'
        ELSE 'Stable'
    END AS productRevenue_trend
FROM 
    SalesWithQuarters
ORDER BY 
    product_id, 
    cal_year,
    fiscal_quarter_group;
SELECT * FROM CJTONG.EXPLAIN_OPERATOR WHERE EXPLAIN_TIME = (SELECT MAX(EXPLAIN_TIME) FROM CJTONG.EXPLAIN_OPERATOR);