USE DATABASE FROSTYFRIDAY;
USE SCHEMA CHALLENGES;

create stage frosty_stage;

create or replace file format frosty_csv
field_optionally_enclosed_by = '"'
skip_header = 1;

--challenge

select ORDER_ID AS COLUMN_POSITION, TYPE as DATA_TYPE
from table(
  infer_schema(
    LOCATION => '@frosty_stage',
    FILE_FORMAT => 'frosty_csv'
  )
);

-- load the data into a table

create or replace file format frosty_csv_parseheader
parse_header = true;

CREATE OR REPLACE TABLE WEEK53
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION => '@frosty_stage'
          , FILE_FORMAT => 'frosty_csv_parseheader'
          , IGNORE_CASE => TRUE
        )
    )
);

COPY into WEEK53 from @frosty_stage FILE_FORMAT = (FORMAT_NAME= 'frosty_csv_parseheader') MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

SELECT * FROM WEEK53;
