-- ******************************************************************
-- Name:    CJ Jingren Tong
-- ID:      152464194
-- Date:    November 4th, 2023
-- Purpose: Business Analytic Application
-- ******************************************************************

-- ******************************************************************
-- **********   Sales Volumes Analysis by Fiscal Quarter   **********
-- ******************************************************************
-- By Store 
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
    
--  By Product 
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

-- By Age Group 
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

-- ******************************************************************
-- **********   Sales Revenue Analysis by Fiscal Quarter   **********
-- ******************************************************************
-- By Store 
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

--  By Product 
SELECT 
    fiscal_quarter_group, 
    calender_year,
    product_id, 
    product_name, 
    SUM(sale_revenue) AS total_sales_revenue
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

-- By Age Group 
SELECT 
    fiscal_quarter_group, 
    calender_year,
    ageGroup_key, 
    ageGroup_name, 
    SUM(sale_revenue) AS total_sales_revenue
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

-- ******************************************************************
-- **********   Sales Profit Analysis by Fiscal Quarter   ***********
-- ******************************************************************
-- By Store 
SELECT 
    fiscal_quarter_group, 
    calender_year,
    store_id, 
    store_name, 
    SUM(sale_profit) AS total_sales_profit
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

--  By Product 
SELECT 
    fiscal_quarter_group, 
    calender_year,
    product_id, 
    product_name, 
    SUM(sale_profit) AS total_sales_profit
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

-- By Age Group 
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


-- ******************************************************************
-- **********   Product Line Analysis by Fiscal Quarter   ***********
-- **********        Measured by revenue and profit       ***********
-- ******************************************************************
-- Most / Least Successful products
-- Option 1: Output is organized from the most successful to the least successful products in each fiscal quarter
-- Profit gives a better indication of financial success since it accounts for the costs. 
SELECT 
    fiscal_quarter_group, 
    calender_year,
    product_id, 
    product_name, 
    SUM(sale_profit) AS total_profit,
    SUM(sale_revenue) AS total_revenue
FROM 
    sales_fact
GROUP BY 
    fiscal_quarter_group, 
    calender_year,
    product_id, 
    product_name
ORDER BY 
    calender_year,
    fiscal_quarter_group, 
    total_profit DESC, 
    total_revenue DESC;

-- Option 2: Create a View for all Product Analysis, and pick out the most / least successful products in each fiscal quarter
-- Profit gives a better indication of financial success since it accounts for the costs. 
CREATE OR REPLACE VIEW product_analysis AS
SELECT 
    fiscal_quarter_group, 
    calender_year,
    product_id, 
    product_name, 
    SUM(sale_profit) AS total_profit,
    SUM(sale_revenue) AS total_revenue
FROM 
    sales_fact
GROUP BY 
    calender_year,
    fiscal_quarter_group, 
    product_id, 
    product_name; 

-- Most Successful Product based on the View we have just created 
SELECT a.*
FROM product_analysis a
JOIN (
    SELECT fiscal_quarter_group, calender_year, MAX(total_profit) as max_profit
    FROM product_analysis
    GROUP BY fiscal_quarter_group, calender_year
) b ON a.fiscal_quarter_group = b.fiscal_quarter_group 
       AND a.calender_year = b.calender_year
       AND a.total_profit = b.max_profit
ORDER BY a.calender_year, a.fiscal_quarter_group;

-- Least Successful Product based on the View we have just created 
SELECT a.*
FROM product_analysis a
JOIN (
    SELECT fiscal_quarter_group, calender_year, MIN(total_profit) as min_profit
    FROM product_analysis
    GROUP BY fiscal_quarter_group, calender_year
) b ON a.fiscal_quarter_group = b.fiscal_quarter_group 
       AND a.calender_year = b.calender_year
       AND a.total_profit = b.min_profit
ORDER BY a.calender_year, a.fiscal_quarter_group;

-- Most / Least Successful Age Group
-- Option 1: Output is organized from the most successful to the least successful age group in each fiscal quarter
-- Profit gives a better indication of financial success since it accounts for the costs. 
SELECT 
    fiscal_quarter_group, 
    calender_year,
    ageGroup_key, 
    ageGroup_name, 
    SUM(sale_profit) AS total_profit,
    SUM(sale_revenue) AS total_revenue
FROM 
    sales_fact
GROUP BY 
    fiscal_quarter_group, 
    calender_year,
    ageGroup_key, 
    ageGroup_name
ORDER BY 
    calender_year,
    fiscal_quarter_group, 
    total_profit DESC, 
    total_revenue DESC;

-- Option 2: Create a View for all Age Group Analysis, and pick out the most / least successful age group in each fiscal quarter
-- Profit gives a better indication of financial success since it accounts for the costs. 
CREATE OR REPLACE VIEW ageGroup_analysis AS
SELECT 
    fiscal_quarter_group, 
    calender_year,
    ageGroup_key, 
    ageGroup_name, 
    SUM(sale_profit) AS total_profit,
    SUM(sale_revenue) AS total_revenue
FROM 
    sales_fact
GROUP BY 
    calender_year,
    fiscal_quarter_group, 
    ageGroup_key, 
    ageGroup_name;

-- Most Successful Age Group based on the View we have just created 
SELECT a.*
FROM ageGroup_analysis a
JOIN (
    SELECT fiscal_quarter_group, calender_year, MAX(total_profit) as max_profit
    FROM ageGroup_analysis
    GROUP BY fiscal_quarter_group, calender_year
) b ON a.fiscal_quarter_group = b.fiscal_quarter_group 
       AND a.calender_year = b.calender_year
       AND a.total_profit = b.max_profit
ORDER BY a.calender_year, a.fiscal_quarter_group;

-- Least Successful Age Group based on the View we have just created 
SELECT a.*
FROM ageGroup_analysis a
JOIN (
    SELECT fiscal_quarter_group, calender_year, MIN(total_profit) as min_profit
    FROM ageGroup_analysis
    GROUP BY fiscal_quarter_group, calender_year
) b ON a.fiscal_quarter_group = b.fiscal_quarter_group 
       AND a.calender_year = b.calender_year
       AND a.total_profit = b.min_profit
ORDER BY a.calender_year, a.fiscal_quarter_group;


-- Product Trends 
-- Sales revenue is used for growth analysis as it directly reflects the market demand and sales performance of a product
-- ** Since some products might not have any sales during some fiscal_quarter_group, so to avoid comparing with last available 
-- ** quarter, instead we need to compare based on the actual chronological order. 
-- Have created a CTE (temporary view) that listed all combinations of products and fiscal quarters, and join with sales_fact 
-- table to get the actual sales data. Then perform a self-join on this derived table to compare each quarter's sales with the 
-- sales from the previous quarter.
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


-- ******************************************************************
-- **********       Store Analysis by Fiscal Quarter      ***********
-- **********        Measured by revenue and profit       ***********
-- ******************************************************************

-- Most / Least Successful Store 
-- Profit gives a better indication of financial success since it accounts for the costs. 
-- Option 1: Output is organized from the most successful to the least successful stores in each fiscal quarter
SELECT 
    fiscal_quarter_group, 
    calender_year,
    store_id, 
    store_specification, 
    store_name, 
    SUM(sale_profit) AS total_profit, 
    SUM(sale_revenue) AS total_revenue
FROM 
    sales_fact
GROUP BY 
    fiscal_quarter_group, 
    calender_year,
    store_id, 
    store_specification, 
    store_name
ORDER BY 
    calender_year,
    fiscal_quarter_group,  
    total_profit DESC,
    total_revenue DESC;

-- Option 2: Create a View for all Store Analysis, and pick out the most / least successful stores in each fiscal quarter
-- Profit gives a better indication of financial success since it accounts for the costs. 
CREATE OR REPLACE VIEW store_analysis AS
SELECT 
    fiscal_quarter_group, 
    calender_year,
    store_id, 
    store_specification, 
    store_name, 
    SUM(sale_profit) AS total_profit, 
    SUM(sale_revenue) AS total_revenue
FROM 
    sales_fact
GROUP BY 
    fiscal_quarter_group, 
    calender_year,
    store_id, 
    store_specification, 
    store_name;

-- Most Successful Store based on the View we have just created 
SELECT s.*
FROM store_analysis s
JOIN (
    SELECT fiscal_quarter_group, calender_year, MAX(total_profit) as max_profit
    FROM store_analysis
    GROUP BY fiscal_quarter_group, calender_year
) p ON s.fiscal_quarter_group = p.fiscal_quarter_group 
    AND s.calender_year = p.calender_year
    AND s.total_profit = p.max_profit
ORDER BY s.calender_year, s.fiscal_quarter_group;

-- Least Successful Store based on the View we have just created 
SELECT s.*
FROM store_analysis s
JOIN (
    SELECT fiscal_quarter_group, calender_year, MIN(total_profit) as min_profit
    FROM store_analysis
    GROUP BY fiscal_quarter_group, calender_year
) p ON s.fiscal_quarter_group = p.fiscal_quarter_group 
    AND s.calender_year = p.calender_year
    AND s.total_profit = p.min_profit
ORDER BY s.calender_year, s.fiscal_quarter_group;

-- Store Trend  
-- Sales revenue is used for growth analysis as it directly reflects the market demand and sales performance of a store.
-- ** Since some stores does not have any sales during some fiscal_quarter_group, so to avoid comparing with last available 
-- ** quarter, instead we need to compare based on the actual chronological order. 
-- Have created a CTE (temporary view) that listed all combinations of stores and fiscal quarters, and join with sales_fact 
-- table to get the actual sales data.
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


-- ******************************************************************
-- *************          Additional Analysis          **************
-- ******************************************************************
 
-- Names have been most successful by volume 
-- Following sums the sale_quantity for each customer (name) and orders the results in descending order 
-- of total_volume, so the most successful product names by volume will be at the top.
SELECT customer_fname || ' ' || customer_lname AS customer_name, SUM(sale_quantity) AS total_volume
FROM sales_fact
GROUP BY customer_fname, customer_lname
ORDER BY total_volume DESC;

-- If just want to output the most successful name 
SELECT customer_fname || ' ' || customer_lname AS customer_name, SUM(sale_quantity) AS total_volume
FROM sales_fact
GROUP BY customer_fname, customer_lname
ORDER BY total_volume DESC
FETCH FIRST ROW ONLY;

-- Gender has been most successful by volume
SELECT customer_gender, SUM(sale_quantity) AS total_volume
FROM sales_fact
GROUP BY customer_gender
ORDER BY total_volume DESC;

-- If just want to output the most successful gender 
SELECT customer_gender, SUM(sale_quantity) AS total_volume
FROM sales_fact
GROUP BY customer_gender
ORDER BY total_volume DESC
FETCH FIRST ROW ONLY;

-- Top sales person for the quarter
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

-- Percentage of sales of cash vs credit card 
-- Refer to my PAYMENTS dimension table, available credit card payments are: Mastercard and Visa 
SELECT
  payment_summary.payment_type,
  SUM(payment_summary.sale_revenue) AS total_revenue,
  (
    (CAST(SUM(payment_summary.sale_revenue) AS DECIMAL(20,2))  / 
    CAST((SELECT SUM(sale_revenue) FROM sales_fact) AS DECIMAL(20,2))) * 100
  ) AS percentage_of_total_revenue
FROM (
  SELECT
    sf.sale_revenue,
    CASE
      WHEN p.payment_type IN ('MasterCard', 'Visa') THEN 'Credit Card'
      WHEN p.payment_type = 'Cash' THEN 'Cash'
      ELSE 'Other'
    END AS payment_type
  FROM sales_fact sf
  JOIN payments p ON sf.payment_type_key = p.payment_type_key
) AS payment_summary
GROUP BY payment_summary.payment_type
HAVING payment_summary.payment_type IN ('Cash', 'Credit Card');

-- Percentage of Sales that using marketing campaign
-- Option 1: If we just simplily need the percentage of sales that used a marketing campaign
SELECT 
(
    (CAST(SUM(market_campaign_dollar_amount) AS DECIMAL(20,2))  / 
    CAST(SUM(sale_revenue) AS DECIMAL(20,2))) * 100
) AS percentage_of_sales_with_campaign
FROM sales_fact;

-- Option 2: If we do need a more detailed information about the marketing campaigns, while including the 
-- percentage of sales for each specific campaign
SELECT
    pc.promotion_name, 
    pc.promotion_description,
    (
        (CAST(SUM(sf.market_campaign_dollar_amount) AS DECIMAL(20,2))  / 
        CAST((SELECT SUM(sale_revenue) FROM sales_fact) AS DECIMAL(20,2))) * 100
    ) AS percentage_of_total_revenue
FROM sales_fact sf
JOIN promotions_n_campaign pc ON sf.promcamp_key = pc.promcamp_key
WHERE sf.is_market_campaign
GROUP BY pc.promotion_name, pc.promotion_description; 


-- ******************************************************************
-- ***********     Analysis Against Reference Tables     ************
-- ******************************************************************

-- Ten cities should open stores in, based on population 
-- As we want to consider where to open stores, we can find the top 10 cities with the highest populations for the year 2022 
-- (or the latest available year)
SELECT "City", "Population"
FROM population
WHERE "Year Recorded" = (SELECT MAX("Year Recorded") FROM population)
ORDER BY "Population" DESC
FETCH FIRST 10 ROWS ONLY;

-- Names should we expect be the most popular for personalized product 
-- Since the business products cater to a wide range of age groups, the strategy to identify the most popular names should consider 
-- a broader time range rather than focusing only on the latest year. This approach will help capture popular names across different 
-- age groups. 
SELECT "First Name", SUM("Frequency") as TotalFrequency
FROM babyNames
WHERE "Birth Year" BETWEEN YEAR(CURRENT_DATE) - 120 AND YEAR(CURRENT_DATE)
GROUP BY "First Name"
ORDER BY TotalFrequency DESC
FETCH FIRST 10 ROWS ONLY;

-- If we only want the most popular names being outputted: 
SELECT "First Name", SUM("Frequency") as TotalFrequency
FROM babyNames
WHERE "Birth Year" BETWEEN YEAR(CURRENT_DATE) - 120 AND YEAR(CURRENT_DATE)
GROUP BY "First Name"
ORDER BY TotalFrequency DESC
FETCH FIRST ROW ONLY;
