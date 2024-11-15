-- Below trigger checks the value of 'employee_role' before it gets inserted into the table, 
-- End of employee_role value must be one of the values in stores store_specification column 

CREATE OR REPLACE TRIGGER check_emp_before_insert
BEFORE INSERT ON employees
REFERENCING NEW AS new_row
FOR EACH ROW
MODE DB2SQL
BEGIN ATOMIC
    DECLARE employeePositionSubStr VARCHAR(5); -- 
    DECLARE storeIdentification INTEGER; --
    -- 0 is FALSE, 1 is TRUE
    DECLARE checkinvalidRole INTEGER DEFAULT 0; -- 
    
    IF new_row.employee_role LIKE 'General%' THEN 
        SET employeePositionSubStr = SUBSTR(new_row.employee_role, 23); -- 
    ELSEIF new_row.employee_role LIKE 'Assistant%' THEN 
        SET employeePositionSubStr = SUBSTR(new_row.employee_role, 19); -- 
    ELSEIF new_row.employee_role LIKE 'Sales%' THEN 
        SET employeePositionSubStr = SUBSTR(new_row.employee_role, 22); -- 
    ELSEIF new_row.employee_role LIKE 'CEO%' THEN
        SET employeePositionSubstr = NULL; --
        SET checkinvalidRole = 0; --
    ELSE 
        SET employeePositionSubstr = NULL; --
        SET checkinvalidRole = 1; --
    END IF; --
    
    IF employeePositionSubStr IS NOT NULL THEN  
        SET storeIdentification = (SELECT store_id FROM stores WHERE store_specification = employeePositionSubstr); -- 

        IF storeIdentification IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid employee job: must include format as <job title><space><store_specification>'; -- 
        END IF;--
    ELSE 
        IF checkinvalidRole = 1 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid employee job: must choose from General manager, assistant manager, or Sales Representative and followed by <store_specification>'; -- 
        END IF; --     
    END IF; --     
END; 