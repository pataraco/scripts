
-- 13.0.0  Use High-Performing Functions
--         In order to do this lab, you can key SQL commands presented in this
--         lab directly into a worksheet. You can also use the code file for
--         this lab that was provided at the start of the class. To use the
--         file, simply drag and drop it into an open worksheet. It is not
--         recommended that you cut and paste from the workbook pdf as that
--         sometimes results in errors.
--         This lab should take approximately 10 minutes to complete.

-- 13.1.0  Use Approximate Count Functions

-- 13.1.1  Navigate to [Worksheets] and create a worksheet named *Function
--         Junction*.

-- 13.1.2  If you haven’t created the class database or warehouse, do it now

CREATE WAREHOUSE IF NOT EXISTS LEARNING;
CREATE DATABASE IF NOT EXISTS LEARNING;


-- 13.1.3  Alter the session so it does not use cached results:

ALTER SESSION SET use_cached_result=false;


-- 13.1.4  Set the Worksheet contexts as follows:

USE ROLE LEARNING;
USE WAREHOUSE LEARNING;
USE DATABASE SNOWFLAKE_SAMPLE_DATA;
USE SCHEMA TPCH_SF100;


-- 13.1.5  Change the virtual warehouse size to XSmall, then suspend and resume
--         the warehouse to clear any data in the warehouse cache:

ALTER WAREHOUSE LEARNING
    SET WAREHOUSE_SIZE = 'XSmall';

ALTER WAREHOUSE LEARNING SUSPEND;
ALTER WAREHOUSE LEARNING RESUME;


-- 13.1.6  Use the query below to determine an approximate count with
--         Snowflake’s Hyperloglog high-performing function:

SELECT HLL(l_orderkey) FROM lineitem;


-- 13.1.7  Suspend and resume the warehouse again to clear the data cache.

-- 13.1.8  Execute the regular COUNT version of the query:

SELECT COUNT(DISTINCT l_orderkey) FROM lineitem;


-- 13.1.9  Compare the execution time of the two queries in steps 4 and 6.

-- 13.1.10 Note that the HLL approximate count version is much faster than the
--         regular count version.

-- 13.2.0  Use Percentile Estimation Functions
--         The APPROX_PERCENTILE function is the more efficient version of the
--         regular SQL MEDIAN function.

-- 13.2.1  Change your warehouse size to Medium:

ALTER WAREHOUSE LEARNING
    SET WAREHOUSE_SIZE = 'Medium';

ALTER WAREHOUSE LEARNING SUSPEND;
ALTER WAREHOUSE LEARNING RESUME;


-- 13.2.2  Start by using the SQL Median Function. Given the lineitem table with
--         over 600 million rows, the following statement determines the median
--         extended price in the table:

USE SCHEMA SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000;
SELECT MEDIAN(l_extendedprice) FROM LINEITEM;


-- 13.2.3  Review the query results returned, as well as the total duration time
--         the statement took to complete.

-- 13.2.4  Suspend the warehouse to flush the data cache:


ALTER WAREHOUSE LEARNING SUSPEND;
ALTER WAREHOUSE LEARNING RESUME;


-- 13.2.5  Run the Percentile Estimation Function on the same lineitem table to
--         find the approximate 50th percentile of extended price in the
--         lineitem table:

SELECT APPROX_PERCENTILE(l_extendedprice, 0.5) FROM LINEITEM;


-- 13.2.6  Review the time it took to complete, and the value returned. Not only
--         was it faster, but it produced a result almost identical to that of
--         MEDIAN.

-- 13.2.7  Suspend and resize the warehouse

ALTER WAREHOUSE LEARNING SET WAREHOUSE_SIZE=XSmall;
ALTER WAREHOUSE LEARNING SUSPEND;

