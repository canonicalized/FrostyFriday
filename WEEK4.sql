USE DATABASE FROSTYFRIDAY;
USE SCHEMA CHALLENGES;

CREATE OR REPLACE STAGE S3_FF_WEEK4
    URL = 's3://frostyfridaychallenges/challenge_4/';
    
-- SHOW STAGES;

-- SELECT DISTINCT METADATA$FILENAME AS FILENAME
-- FROM @S3_FF_WEEK4;

-- json file format
CREATE OR REPLACE FILE FORMAT JSON_FORMAT
TYPE = 'JSON'
STRIP_OUTER_ARRAY = TRUE
;

-- check file contents
SELECT  $1
FROM @S3_FF_WEEK4
(FILE_FORMAT => 'JSON_FORMAT');

-- CTE to build our table
WITH L1 AS (
    SELECT
        $1,
        $1:Era::varchar as ERA,
        $1:Houses::array as HOUSES
    FROM @S3_FF_WEEK4
    (FILE_FORMAT => 'JSON_FORMAT')
),
L2 AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY m.value:Birth::date ASC) AS ID,
        m.index + 1 AS INTER_HOUSE_ID,
        ERA,
        h.value:House::varchar AS HOUSE,
        m.value:Name::varchar AS NAME,
--NICKNAMES
        m.value:"Nickname"[0]::varchar AS NICKNAME_1,
        m.value:"Nickname"[1]::varchar AS NICKNAME_2,
        m.value:"Nickname"[2]::varchar AS NICKNAME_3,
        
        m.value:Birth::date AS BIRTH,
        m.value:"Place of Birth"::varchar AS PLACE_OF_BIRTH,
        m.value:"Start of Reign"::date AS START_OF_REIGN,
--QUEENS
        m.value:"Consort\/Queen Consort"[0]::varchar AS QUEEN_OR_QUEEN_CONSORT_1,
        m.value:"Consort\/Queen Consort"[1]::varchar AS QUEEN_OR_QUEEN_CONSORT_2,
        m.value:"Consort\/Queen Consort"[2]::varchar AS QUEEN_OR_QUEEN_CONSORT_3,
        
        m.value:"End of Reign"::date AS END_OF_REIGN,
        m.value:Duration::varchar as DURATION,
        m.value:Death::varchar as DEATH,
        REPLACE(m.value:"Age at Time of Death",' years','')::NUMBER as AGE_AT_TIME_OF_DEATH_YEARS,
        m.value:"Place of Death"::varchar as PLACE_OF_DEATH,
        m.value:"Burial Place"::varchar as BURIAL_PLACE
    FROM L1,
    LATERAL FLATTEN(input => HOUSES) h,
    LATERAL FLATTEN(input => h.value:"Monarchs") m
    ORDER BY BIRTH ASC
)
SELECT * FROM L2;
