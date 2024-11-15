-- Create a stored procedure to insert employee information
SET SERVEROUTPUT ON; 

CREATE OR REPLACE PROCEDURE insertEmployeeInfo
LANGUAGE SQL
BEGIN
    DECLARE updated_rows INTEGER DEFAULT 0; -- 

    -- Update all rows in sales_fact where employee details are not populated
   UPDATE sales_fact sf
    SET employee_name = 
        (SELECT CONCAT(CONCAT(INITCAP(e.employee_fname), ' '), INITCAP(e.employee_lname)) 
         FROM employees e
         WHERE e.employee_unique_key = sf.employee_unique_key)
    WHERE sf.employee_name IS NULL; --
    
    GET DIAGNOSTICS updated_rows = ROW_COUNT; --
    
    CALL DBMS_OUTPUT.PUT_LINE('Updated_rows: ' || updated_rows);--

END; 