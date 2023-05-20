USE DATABASE FROSTYFRIDAY;
USE SCHEMA CHALLENGES;

CREATE STAGE IF NOT EXISTS S3_FF_WEEK2
    URL = 's3://frostyfridaychallenges/challenge_2/';
    
-- SHOW STAGES;
-- LIST @S3_FF_WEEK2;

CREATE FILE FORMAT IF NOT EXISTS PARQUET_FORMAT
  TYPE = 'PARQUET'
  -- COMPRESSION = 'SNAPPY'
;

-- SHOW FILE FORMATS;

-- SELECT DISTINCT METADATA$FILENAME AS FILENAME
-- FROM @S3_FF_WEEK2;

-- see results
SELECT  $1
FROM @S3_FF_WEEK2
(FILE_FORMAT => 'PARQUET_FORMAT');

-- create table: infer schema from file instead of manually mapping the column names - preserves order of columns, avoids missing column names wich for some rows might not be present
CREATE TABLE IF NOT EXISTS CHALLENGES.WEEK2 USING template (
SELECT array_agg(object_construct(*))
FROM table (
  infer_schema(
        location => '@S3_FF_WEEK2/'
        , file_format => 'PARQUET_FORMAT'
        , ignore_case => TRUE
        )
    )
);

--load the data
COPY INTO CHALLENGES.WEEK2
FROM (
    SELECT 
    $1:"employee_id"
    , $1:"first_name"
    , $1:"last_name"
    , $1:"email"
    , $1:"street_num"
    , $1:"street_name"
    , $1:"city"
    , $1:"postcode"
    , $1:"country"
    , $1:"country_code"
    , $1:"time_zone"
    , $1:"payroll_iban"
    , $1:"dept"
    , $1:"job_title"
    , $1:"education"
    , $1:"title"
    , $1:"suffix"
    FROM @S3_FF_WEEK2
    (FILE_FORMAT => 'PARQUET_FORMAT')
);

SELECT * FROM FROSTYFRIDAY.CHALLENGES.WEEK2;

CREATE VIEW IF NOT EXISTS FROSTYFRIDAY.CHALLENGES.WEEK2_VIEW
AS
SELECT
     "EMPLOYEE_ID","DEPT","JOB_TITLE" from FROSTYFRIDAY.CHALLENGES.WEEK2;

SELECT * FROM FROSTYFRIDAY.CHALLENGES.WEEK2_VIEW;

CREATE STREAM IF NOT EXISTS STREAM_WEEK2
ON VIEW FROSTYFRIDAY.CHALLENGES.WEEK2_VIEW;

-- SHOW STREAMS;
SELECT * FROM STREAM_WEEK2;

UPDATE FROSTYFRIDAY.CHALLENGES.WEEK2 SET COUNTRY = 'Japan' WHERE EMPLOYEE_ID = 8;
UPDATE FROSTYFRIDAY.CHALLENGES.WEEK2 SET LAST_NAME = 'Forester' WHERE EMPLOYEE_ID = 22;
UPDATE FROSTYFRIDAY.CHALLENGES.WEEK2 SET DEPT = 'Marketing' WHERE EMPLOYEE_ID = 25;
UPDATE FROSTYFRIDAY.CHALLENGES.WEEK2 SET TITLE = 'Ms' WHERE EMPLOYEE_ID = 32;
UPDATE FROSTYFRIDAY.CHALLENGES.WEEK2 SET JOB_TITLE = 'Senior Financial Analyst' WHERE EMPLOYEE_ID = 68;

SELECT * FROM STREAM_WEEK2;
