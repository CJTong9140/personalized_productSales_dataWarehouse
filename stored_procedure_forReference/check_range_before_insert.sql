-- *********************************************************
-- Name:    CJ Jingren Tong
-- Date:    October 25th, 2023
-- Purpose: Trigger to check lifeExpectancy table insertion 
-- *********************************************************

-- Below trigger checks the value of 'Period Start Year' and 'Period End Year' in LifeExpectancy table before it gets inserted into the table, 
-- Both value must be earlier than current year, and larger than 0. 
-- Also, 'Period End Year' must be larger than 'Period Start Year'

CREATE TRIGGER check_range_before_insert
BEFORE INSERT ON lifeExpectancy
REFERENCING NEW AS n
FOR EACH ROW
BEGIN 
    -- Check "Period Start Year" and "Period End Year" are less than current year
    IF (n."Period Start Year" >= YEAR(CURRENT_DATE) OR n."Period End Year" >= YEAR(CURRENT_DATE)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Period Start Year or Period End Year must be less than current year';--
    END IF;--
    
    -- Check "Period Start Year" and "Period End Year" are more than 0
    IF (n."Period Start Year" <= 0 OR n."Period End Year" <= 0) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Period Start Year or Period End Year must be more than 0';--
    END IF;--

    -- Check "Period Start Year" is less than "Period End Year"
    IF n."Period Start Year" >= n."Period End Year" THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Period Start Year should be less than Period End Year.';--
    END IF;-- 
END;
