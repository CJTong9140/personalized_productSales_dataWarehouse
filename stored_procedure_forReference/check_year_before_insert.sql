-- *********************************************************
-- Name:    CJ Jingren Tong
-- Date:    October 25th, 2023
-- Purpose: Trigger to check population table insertion 
-- *********************************************************

-- Below trigger checks the value of 'Year' in Population table before it gets inserted into the table, 
-- Year value must be earlier than current year, and larger than 0. 

CREATE OR REPLACE TRIGGER check_year_before_insert
BEFORE INSERT ON population
REFERENCING NEW AS new_row
FOR EACH ROW
  BEGIN 
    IF new_row."Year Recorded" < 0 OR new_row."Year Recorded" > YEAR(CURRENT_DATE) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Year Value';-- 
    END IF;--
  END; 
