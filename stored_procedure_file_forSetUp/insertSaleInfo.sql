-- Create a stored procedure to insert sale information such as sale_revenue, sale_profit, tax_dollar_amount
SET SERVEROUTPUT ON; 

CREATE OR REPLACE PROCEDURE insertSaleInfo
LANGUAGE SQL
BEGIN
    DECLARE updated_rows INTEGER DEFAULT 0; -- 
    DECLARE wholeSalePrice DECIMAL(10, 2) DEFAULT 0.0; --
    DECLARE v_done INT DEFAULT 0;--
    DECLARE totalDonationAmt DECIMAL(7, 2) DEFAULT 0.0; --
    DECLARE donationAmt DECIMAL(7, 2) DEFAULT 0.0; -- 
    DECLARE v_rows_affected INTEGER DEFAULT 0;-- 
    DECLARE v_sales_fact_key INTEGER;--
    DECLARE v_product_id INTEGER;--
    DECLARE v_product_list_price DECIMAL(10, 2);--
    DECLARE v_sale_quantity INTEGER;--
    DECLARE v_promotion_dollar_amount DECIMAL(10, 2);--
    DECLARE v_market_campaign_dollar_amount DECIMAL(10, 2);--

    DECLARE cur CURSOR WITH HOLD FOR
        SELECT sales_fact_key, product_id, product_list_price, sale_quantity, promotion_dollar_amount, market_campaign_dollar_amount
        FROM sales_fact
        WHERE product_id IS NOT NULL;--
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET v_done = 1;--
        
    OPEN cur; --
    
    FETCH FROM cur INTO v_sales_fact_key, v_product_id, v_product_list_price, v_sale_quantity, v_promotion_dollar_amount, v_market_campaign_dollar_amount;--
    
    -- Loop through rows
    WHILE v_done = 0 DO
        -- Discounted
        IF v_promotion_dollar_amount != 0.0 THEN
            UPDATE sales_fact 
            SET 
                sale_revenue = v_sale_quantity * v_product_list_price - v_promotion_dollar_amount,
                sale_profit = (v_sale_quantity * v_product_list_price - v_promotion_dollar_amount) - (v_sale_quantity * (SELECT product_cost FROM products WHERE product_id = v_product_id)), 
                tax_dollar_amount = (v_sale_quantity * v_product_list_price - v_promotion_dollar_amount) * 13/100
            WHERE sales_fact_key = v_sales_fact_key; --
            
            GET DIAGNOSTICS v_rows_affected = ROW_COUNT; --
            SET updated_rows = updated_rows + v_rows_affected; --
        -- Donation    
        ELSEIF v_market_campaign_dollar_amount != 0.0 THEN
        
            -- Already checked in insertPromoCampn and made sure donation is not exceeding set amount. 
            -- If exceed, market_campaign_dollar_amount has already been set as 0.0
            
            UPDATE sales_fact 
            SET 
                sale_revenue = v_sale_quantity * v_product_list_price, 
                sale_profit = 0.0,
                tax_dollar_amount = (v_sale_quantity * v_product_list_price) * 13/100
            WHERE sales_fact_key = v_sales_fact_key; --
            
            GET DIAGNOSTICS v_rows_affected = ROW_COUNT; --
            SET updated_rows = updated_rows + v_rows_affected; --
        -- Regular price
        ELSE
            UPDATE sales_fact 
            SET 
                sale_revenue = v_sale_quantity * v_product_list_price, 
                sale_profit = (v_sale_quantity * v_product_list_price) - (v_sale_quantity * (SELECT product_cost FROM products WHERE product_id = v_product_id)), 
                tax_dollar_amount = (v_sale_quantity * v_product_list_price) * 13/100
            WHERE sales_fact_key = v_sales_fact_key; --
            
            GET DIAGNOSTICS v_rows_affected = ROW_COUNT; --
            SET updated_rows = updated_rows + v_rows_affected; --
        END IF; -- 
        FETCH FROM cur INTO v_sales_fact_key, v_product_id, v_product_list_price, v_sale_quantity, v_promotion_dollar_amount, v_market_campaign_dollar_amount;--
    END WHILE;--
    
    -- Close the cursor
    CLOSE cur; --   
        
    CALL DBMS_OUTPUT.PUT_LINE('Updated_rows: ' || updated_rows);--   

END; 