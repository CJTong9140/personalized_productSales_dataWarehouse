-- Create a stored procedure to insert Store information
SET SERVEROUTPUT ON; 

CREATE OR REPLACE PROCEDURE insertStoreInfo
LANGUAGE SQL
BEGIN
    DECLARE updated_rows INTEGER DEFAULT 0; -- 

    -- Update all rows in sales_fact where store details are not populated
   UPDATE sales_fact sf
    SET (store_specification, store_name) = 
        (SELECT s.store_specification, s.store_name
         FROM stores s
         WHERE sf.store_id = s.store_id)
    WHERE sf.store_name IS NULL or sf.store_specification IS NULL; --
    
    GET DIAGNOSTICS updated_rows = ROW_COUNT; --
    
    CALL DBMS_OUTPUT.PUT_LINE('Updated_rows: ' || updated_rows);--

END; 