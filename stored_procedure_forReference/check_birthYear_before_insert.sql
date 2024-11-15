-- *********************************************************
-- Name:    CJ Jingren Tong
-- Date:    October 24th, 2023
-- Purpose: Trigger to check babyNames table insertion 
-- *********************************************************

-- Below trigger checks the value of 'Birth Year' in BabyNames table before it gets inserted into the table, 
-- Year value must be earlier than current year, and larger than 0. 

CREATE OR REPLACE TRIGGER check_year_before_insert
BEFORE INSERT ON babyNames
REFERENCING NEW AS new_row
FOR EACH ROW
  BEGIN 
    IF new_row."Birth Year" < 0 OR new_row."Birth Year" > YEAR(CURRENT_DATE) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Year Value';-- 
    END IF;--
  END; 