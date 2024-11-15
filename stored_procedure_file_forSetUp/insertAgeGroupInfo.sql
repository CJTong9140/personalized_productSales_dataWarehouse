-- Create a stored procedure to insert age group information based on customer's DOB
SET SERVEROUTPUT ON; 

CREATE OR REPLACE PROCEDURE insertAgeGroupInfo
LANGUAGE SQL
BEGIN
    DECLARE updated_rows INTEGER DEFAULT 0; -- 
    DECLARE currentYear INTEGER DEFAULT 0; -- 
   
   -- Update the sales_fact table using nested subqueries for age calculation and joining with age_groups
    UPDATE 
        sales_fact s
    SET 
        (ageGroup_key, ageGroup_name) = (
            SELECT g.ageGroup_key, g.ageGroup_name
            FROM age_groups g
            WHERE YEAR(CURRENT_DATE) - YEAR(
                (SELECT customer_dob FROM customers c WHERE c.customer_id = s.customer_id)
            ) BETWEEN g.ageGroup_begin AND g.ageGroup_end
        )
    WHERE 
        s.customer_id IN (SELECT customer_id FROM customers); -- 
        
    GET DIAGNOSTICS updated_rows = ROW_COUNT; --
    
    CALL DBMS_OUTPUT.PUT_LINE('Updated_rows: ' || updated_rows);--

END; 