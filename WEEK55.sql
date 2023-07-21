use warehouse sawh;
use database frostyfriday;
use schema challenges;

create or replace stage week55_stage
    url='s3://frostyfridaychallenges/challenge_55/';

LIST @week55_stage;

select *
from table(
  infer_schema(
    LOCATION => '@week55_stage',
    FILE_FORMAT => 'frosty_csv_parseheader'
  )
);

CREATE OR REPLACE TABLE WEEK55
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
      FROM TABLE(
        INFER_SCHEMA(
          LOCATION => '@week55_stage'
          , FILE_FORMAT => 'frosty_csv_parseheader'
          , IGNORE_CASE => TRUE
        )
    )
);

copy into WEEK55 from @week55_stage FILE_FORMAT = (FORMAT_NAME= 'frosty_csv_parseheader') MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE;

SELECT * FROM WEEK55
GROUP BY ALL
ORDER BY SALE_ID;
