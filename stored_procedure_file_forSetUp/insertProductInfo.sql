-- Create a stored procedure to insert Product information
SET SERVEROUTPUT ON; 

CREATE OR REPLACE PROCEDURE insertProductInfo
LANGUAGE SQL
BEGIN
    DECLARE updated_rows INTEGER DEFAULT 0; -- 

    -- Update all rows in sales_fact where product details are not populated
    UPDATE sales_fact sf
    SET (product_name, product_list_price) = 
        (SELECT p.product_name, p.list_price
         FROM products p
         WHERE sf.product_id = p.product_id)
    WHERE sf.product_name IS NULL OR sf.product_list_price IS NULL; --
    
   
    GET DIAGNOSTICS updated_rows = ROW_COUNT; --
    
    CALL DBMS_OUTPUT.PUT_LINE('Updated_rows: ' || updated_rows);--

END; 