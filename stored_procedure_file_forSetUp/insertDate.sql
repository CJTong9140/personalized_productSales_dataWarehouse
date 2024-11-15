-- Create a stored procedure to insert dates from system 2021-01-01 to 2023-12-31
SET SERVEROUTPUT ON; 

CREATE OR REPLACE PROCEDURE insertDates
LANGUAGE SQL
BEGIN
    DECLARE v_date DATE DEFAULT '2021-01-01';--

    WHILE v_date <= '2023-12-31' DO
        INSERT INTO cal_dates (date_detail, cal_year, cal_month, cal_date, day_of_the_week)
        VALUES (
            v_date,
            YEAR(v_date),
            MONTH(v_date),
            DAY(v_date),
            DAYNAME(v_date)
        );--
        SET v_date = v_date + 1 DAY; -- 
    END WHILE;--
END;