-- Store procedure able to fill promotion or campaign information

CREATE OR REPLACE PROCEDURE insertPromoCampn
LANGUAGE SQL
BEGIN
    DECLARE v_sales_fact_key INTEGER;--
    DECLARE v_promcamp_key INTEGER;--
    DECLARE v_is_market_campaign BOOLEAN;--
    DECLARE v_product_list_price DECIMAL(10, 2);--
    DECLARE v_sale_quantity INTEGER;--
    DECLARE v_donationAmt DECIMAL(7, 2);--
    DECLARE v_donationPercentage INTEGER;--
    DECLARE v_discountPercentage INTEGER; --
    DECLARE updated_rows INTEGER DEFAULT 0; --
    DECLARE donationAmt DECIMAL(7, 2); -- 
    DECLARE totalDonationAmt DECIMAL(7, 2) DEFAULT 0.0; --
    DECLARE v_done INT DEFAULT 0;--
    DECLARE v_rows_affected INTEGER DEFAULT 0;--
    
    DECLARE cur CURSOR WITH HOLD FOR
        SELECT sales_fact_key, promcamp_key, is_market_campaign, product_list_price, sale_quantity
        FROM sales_fact
        WHERE promcamp_key IS NOT NULL;--
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET v_done = 1;--
    
    OPEN cur; --
    
    FETCH FROM cur INTO v_sales_fact_key, v_promcamp_key, v_is_market_campaign, v_product_list_price, v_sale_quantity;--

    -- Loop through rows
    WHILE v_done = 0 DO
        IF v_is_market_campaign THEN
            SELECT donation_amount, donation_percentage 
            INTO v_donationAmt, v_donationPercentage 
            FROM promotions_n_campaign 
            WHERE promcamp_key = v_promcamp_key;--

            IF v_donationPercentage != 0 THEN
                UPDATE sales_fact 
                SET market_campaign_dollar_amount = v_donationPercentage * v_product_list_price * v_sale_quantity / 100
                WHERE sales_fact_key = v_sales_fact_key;--
                GET DIAGNOSTICS v_rows_affected = ROW_COUNT; --
                SET updated_rows = updated_rows + v_rows_affected; -- 

            ELSE
                IF totalDonationAmt < donationAmt THEN      
                    UPDATE sales_fact 
                    SET market_campaign_dollar_amount = v_product_list_price * v_sale_quantity
                    WHERE sales_fact_key = v_sales_fact_key; --
                    GET DIAGNOSTICS v_rows_affected = ROW_COUNT; --
                    SET updated_rows = updated_rows + v_rows_affected; --

                    
                    SELECT market_campaign_dollar_amount 
                    INTO donationAmt 
                    FROM sales_fact 
                    WHERE sales_fact_key = v_sales_fact_key; --
                    SET totalDonationAmt = totalDonationAmt + donationAmt; --
                ELSE
                    SET donationAmt = totalDonationAmt; -- 
                    UPDATE sales_fact 
                    SET market_campaign_dollar_amount = 0.0
                    WHERE sales_fact_key = v_sales_fact_key; --
                    GET DIAGNOSTICS v_rows_affected = ROW_COUNT; --
                    SET updated_rows = updated_rows + v_rows_affected; --

                END IF; --    
            END IF; -- 
             
        ELSE
            SELECT discount_percentage
            INTO v_discountPercentage 
            FROM promotions_n_campaign 
            WHERE promcamp_key = v_promcamp_key;-- 
            
            IF v_discountPercentage != 0 THEN
                UPDATE sales_fact 
                SET promotion_dollar_amount = v_discountPercentage * v_product_list_price * v_sale_quantity / 100
                WHERE sales_fact_key = v_sales_fact_key;--
                GET DIAGNOSTICS v_rows_affected = ROW_COUNT; --
                SET updated_rows = updated_rows + v_rows_affected; --
            END IF;--
        END IF; --
        FETCH FROM cur INTO v_sales_fact_key, v_promcamp_key, v_is_market_campaign, v_product_list_price, v_sale_quantity;--
    END WHILE;--
    -- Close the cursor
    CLOSE cur; --   
        
    CALL DBMS_OUTPUT.PUT_LINE('Updated_rows: ' || updated_rows);--

END; 