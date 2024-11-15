-- Create a stored procedure to insert date information based on the item purchase CURRENT_TIMESTAMP
SET SERVEROUTPUT ON; 

CREATE OR REPLACE PROCEDURE insertDateInfo
LANGUAGE SQL
BEGIN
    DECLARE updated_rows INTEGER DEFAULT 0; -- 

    -- Update all rows in sales_fact where date details are not populated
    UPDATE sales_fact sf
    SET (date_key, fiscal_quarter_group, calender_year, calender_month, calender_date) = 
        (SELECT c.date_key, c.fiscal_quarter_group, c.cal_year, c.cal_month, c.cal_date
         FROM cal_dates_with_fiscal c 
         WHERE DATE(sf.item_scan_timestamp) = c.date_detail)
    WHERE sf.date_key IS NULL OR sf.calender_year IS NULL OR sf.calender_month IS NULL OR sf.calender_date IS NULL; --
   
    GET DIAGNOSTICS updated_rows = ROW_COUNT; --
    
    CALL DBMS_OUTPUT.PUT_LINE('Updated_rows: ' || updated_rows);--

END; 