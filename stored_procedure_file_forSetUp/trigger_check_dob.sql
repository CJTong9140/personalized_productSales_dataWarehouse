-- Below trigger checks the value of 'customer_dob' before it gets inserted into the table, 
-- Date of Birth value must be earlier than current date 

CREATE OR REPLACE TRIGGER check_dob_before_insert
BEFORE INSERT ON customers
REFERENCING NEW AS new_row
FOR EACH ROW
WHEN (new_row.customer_dob > CURRENT_DATE)
BEGIN 
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid DOB: Date of Birth cannot be in the future';--
END;