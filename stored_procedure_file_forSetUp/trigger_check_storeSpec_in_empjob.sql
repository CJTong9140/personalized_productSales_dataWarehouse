-- Below trigger checks the value of 'employee_role' at the associated 'employee_unique_key' before it gets inserted into the table, 
-- Employee_role must concatenate with the matching store_specification at the end  

CREATE OR REPLACE TRIGGER check_storeSpec_in_empjob_before_insert
BEFORE INSERT ON sales_fact
REFERENCING NEW AS new_row
FOR EACH ROW
MODE DB2SQL
BEGIN ATOMIC
     DECLARE employeePosition VARCHAR(30); -- 
     DECLARE employeePositionSubStr VARCHAR(5); -- 
     DECLARE storeInfo VARCHAR(5); -- 
     
     SET employeePosition = (SELECT employee_role FROM employees WHERE employee_unique_key = new_row.employee_unique_key); -- 

     IF employeePosition LIKE 'General%' THEN 
        SET employeePositionSubStr = SUBSTR(employeePosition, 23); -- 
     ELSEIF employeePosition LIKE 'Assistant%' THEN 
        SET employeePositionSubStr = SUBSTR(employeePosition, 19); -- 
     ELSEIF employeePosition LIKE 'Sales%' THEN 
        SET employeePositionSubStr = SUBSTR(employeePosition, 22); -- 
     ELSE 
        SET employeePositionSubstr = NULL; --
     END IF; --

     SET storeInfo = (SELECT store_specification FROM stores WHERE store_id = new_row.store_id); -- 
    
     IF storeInfo != employeePositionSubstr THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid employee: Employee is not working for the specified store';--
     END IF;--  
END;