-- Create a stored procedure to insert customer information
SET SERVEROUTPUT ON; 

CREATE OR REPLACE PROCEDURE insertCustomerInfo
LANGUAGE SQL
BEGIN
    DECLARE updated_rows INTEGER DEFAULT 0; -- 

    -- Update all rows in sales_fact where customer details are not populated
    UPDATE sales_fact sf
    SET (customer_fname, customer_lname, customer_gender) = 
        (SELECT c.customer_fname, c.customer_lname, c.customer_gender
         FROM customers c 
         WHERE sf.customer_id = c.customer_id)
    WHERE sf.customer_fname IS NULL OR sf.customer_lname IS NULL OR sf.customer_gender IS NULL; --
    
   
    GET DIAGNOSTICS updated_rows = ROW_COUNT; --
    
    CALL DBMS_OUTPUT.PUT_LINE('Updated_rows: ' || updated_rows);--

END; 