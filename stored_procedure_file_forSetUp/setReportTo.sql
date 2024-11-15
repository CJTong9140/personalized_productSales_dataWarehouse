SET SERVEROUTPUT ON; 

CREATE OR REPLACE PROCEDURE setReportTo (OUT updatedRows INTEGER)
LANGUAGE SQL
BEGIN 
    DECLARE employeeIdentifier CHAR(5); --
    DECLARE amountOfRows INTEGER; -- 
    DECLARE employeePosition VARCHAR(30); --
    DECLARE employeePositionSubStr VARCHAR(5); -- 
    DECLARE reportToEmployeeKey INTEGER; -- 

    SET amountOfRows = (SELECT COUNT(*) FROM employees); --
    SET updatedRows = 0; --
    
    WHILE updatedRows < amountOfRows DO  
        SET employeePosition = (SELECT employee_role FROM employees WHERE employee_unique_key = (100 + 10 * (updatedRows + 1))); --
        SET employeeIdentifier = (SELECT employee_id FROM employees WHERE employee_unique_key = (100 + 10 * (updatedRows + 1))); --

        IF employeePosition LIKE 'General%' THEN 
            SET reportToEmployeeKey = (SELECT employee_unique_key FROM employees WHERE employee_role = 'CEO/Owner' AND employee_id != employeeIdentifier); -- 
        ELSEIF employeePosition LIKE 'Assistant%' THEN
            SET employeePositionSubStr = (SELECT SUBSTR(employee_role, 19) FROM employees WHERE employee_unique_key = (100 + 10 * (updatedRows + 1))); --
            SET reportToEmployeeKey = (SELECT employee_unique_key FROM employees WHERE employee_role = ('General Store Manager ' || employeePositionSubStr) AND employee_id != employeeIdentifier); --
        ELSEIF employeePosition LIKE 'Sales%' THEN
            SET employeePositionSubStr = (SELECT SUBSTR(employee_role, 22) FROM employees WHERE employee_unique_key = (100 + 10 * (updatedRows + 1))); --
            SET reportToEmployeeKey = (SELECT employee_unique_key FROM employees WHERE employee_role = ('Assistant Manager ' || employeePositionSubStr) AND employee_id != employeeIdentifier); -- 
        ELSE 
            SET reportToEmployeeKey = NULL; --
        END IF; --
        
        UPDATE employees SET report_to  = reportToEmployeeKey WHERE employee_unique_key = (100 + 10 * (updatedRows + 1)); -- 
        SET updatedRows = updatedRows + 1; --
    END WHILE; -- 
    
    CALL DBMS_OUTPUT.PUT_LINE('Total amount of updated rows: ' || updatedRows); -- 
END;