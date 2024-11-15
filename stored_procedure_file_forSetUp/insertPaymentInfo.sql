-- Create a stored procedure to insert payment information
SET SERVEROUTPUT ON; 

CREATE OR REPLACE PROCEDURE insertPaymentInfo
LANGUAGE SQL
BEGIN
    DECLARE updated_rows INTEGER DEFAULT 0; -- 

    -- Update all rows in sales_fact where store details are not populated
   UPDATE sales_fact sf
    SET payment_type = 
        (SELECT p.payment_type
         FROM payments p
         WHERE sf.payment_type_key = p.payment_type_key)
    WHERE sf.payment_type IS NULL; --
    
    GET DIAGNOSTICS updated_rows = ROW_COUNT; --
    
    CALL DBMS_OUTPUT.PUT_LINE('Updated_rows: ' || updated_rows);--

END; 