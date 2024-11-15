SET SERVEROUTPUT ON; 

CREATE OR REPLACE PROCEDURE getUniqueSku (OUT product_rows INTEGER, OUT updated_rows INTEGER)
LANGUAGE SQL
BEGIN 
   
    SET updated_rows = 0; -- 
    SET product_rows = (SELECT COUNT(*) FROM products); -- 
    CALL DBMS_OUTPUT.PUT_LINE('Total amount of products to updated: ' || product_rows); -- 
    
    WHILE updated_rows < product_rows DO
        UPDATE products SET sku_number = CONCAT(UPPER(SUBSTR(product_name, 1, 2)), LPAD(TO_CHAR(product_id), 5, '0')) WHERE product_id = updated_rows + 1; --
        SET updated_rows = updated_rows + 1; -- 
    END WHILE; -- 
    CALL DBMS_OUTPUT.PUT_LINE('Total amount of updated rows: ' || updated_rows); -- 

END;