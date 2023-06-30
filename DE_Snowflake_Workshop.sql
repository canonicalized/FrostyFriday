-- ALTER USER canonicalized SET DEFAULT_ROLE = 'SYSADMIN';
USE ROLE SYSADMIN;
CREATE DATABASE AGS_GAME_AUDIENCE;
USE DATABASE AGS_GAME_AUDIENCE;
DROP SCHEMA PUBLIC;
CREATE SCHEMA RAW;
USE SCHEMA RAW;
LS @uni_kishore/kickoff/;

create file format FF_JSON_LOGS
    type = JSON
    strip_outer_array = TRUE;

-- CREATE WAREHOUSE SAWH;
USE WAREHOUSE SAWH;

SELECT $1
FROM @uni_kishore/kickoff/
(FILE_FORMAT => FF_JSON_LOGS);
-- TRUNCATE GAME_LOGS;

COPY INTO GAME_LOGS
FROM @uni_kishore/kickoff/
FILE_FORMAT = (format_name = FF_JSON_LOGS);

SELECT * FROM GAME_LOGS;

CREATE OR REPLACE VIEW LOGS AS (
    SELECT 
        RAW_LOG:agent::text AS agent,
        RAW_LOG:user_event::text AS user_event,
        RAW_LOG:user_login::text AS user_login,
        RAW_LOG:datetime_iso8601::timestamp_ntz AS datetime_iso8601,
        RAW_LOG
    FROM GAME_LOGS
);

SELECT * FROM LOGS;

-- GRADE LESSON 2



SELECT CURRENT_TIMESTAMP();
alter session set timezone = 'UTC';
select current_timestamp();
show parameters like 'timezone';

SELECT * FROM @uni_kishore/updated_feed
(FILE_FORMAT => FF_JSON_LOGS);

COPY INTO GAME_LOGS 
FROM @uni_kishore/updated_feed
FILE_FORMAT = (format_name = FF_JSON_LOGS);

SELECT * FROM GAME_LOGS;

SELECT * FROM LOGS WHERE AGENT IS NULL;

CREATE OR REPLACE VIEW LOGS AS (
    SELECT 
        RAW_LOG:user_event::text AS user_event,
        RAW_LOG:user_login::text AS user_login,
        RAW_LOG:datetime_iso8601::timestamp_ntz AS datetime_iso8601,
        RAW_LOG:ip_address::text AS ip_address,
        RAW_LOG
    FROM GAME_LOGS
    WHERE ip_address IS NOT NULL
);
SELECT * FROM LOGS WHERE USER_LOGIN ilike '%praj%';

-- GRADE LESSON 3

SELECT parse_ip('100.41.16.160','inet'):ipv4;
CREATE SCHEMA ENHANCED;
USE SCHEMA ENHANCED;

--Look up Kishore and Prajina's Time Zone in the IPInfo share using his headset's IP Address with the PARSE_IP function.
select start_ip, end_ip, start_ip_int, end_ip_int, city, region, country, timezone
from IPINFO_GEOLOC.demo.location
where parse_ip('100.41.16.160', 'inet'):ipv4 --Kishore's Headset's IP Address
BETWEEN start_ip_int AND end_ip_int;

--Join the log and location tables to add time zone to each row using the PARSE_IP function.
select logs.*
       , loc.city
       , loc.region
       , loc.country
       , loc.timezone
from AGS_GAME_AUDIENCE.RAW.LOGS logs
join IPINFO_GEOLOC.demo.location loc
where parse_ip(logs.ip_address, 'inet'):ipv4 
BETWEEN start_ip_int AND end_ip_int;


create table ags_game_audience.enhanced.logs_enhanced as(
    --Use two functions supplied by IPShare to help with an efficient IP Lookup Process!
    SELECT logs.ip_address
    , logs.user_login AS GAMER_NAME
    , logs.user_event AS GAME_EVENT_NAME
    , logs.datetime_iso8601 AS GAME_EVENT_UTC
    , city
    , region
    , country
    , timezone AS GAMER_LTZ_NAME
    , CONVERT_TIMEZONE('UTC',timezone,logs.datetime_iso8601) AS GAME_EVENT_LTZ
    , DAYNAME(GAME_EVENT_LTZ) AS DOW_NAME
    , TOD_NAME
    from AGS_GAME_AUDIENCE.RAW.LOGS logs
    JOIN IPINFO_GEOLOC.demo.location loc 
        ON IPINFO_GEOLOC.public.TO_JOIN_KEY(logs.ip_address) = loc.join_key
        AND IPINFO_GEOLOC.public.TO_INT(logs.ip_address) BETWEEN start_ip_int AND end_ip_int
    JOIN AGS_GAME_AUDIENCE.RAW.time_of_day_lu tod
        ON tod.hour = HOUR(GAME_EVENT_LTZ)
);

SELECT * FROM ENHANCED.LOGS_ENHANCED;

--a Look Up table to convert from hour number to "time of day name"
create table ags_game_audience.raw.time_of_day_lu
(  hour number
   ,tod_name varchar(25)
);

USE SCHEMA RAW;

--insert statement to add all 24 rows to the table
insert into time_of_day_lu
values
(6,'Early morning'),
(7,'Early morning'),
(8,'Early morning'),
(9,'Mid-morning'),
(10,'Mid-morning'),
(11,'Late morning'),
(12,'Late morning'),
(13,'Early afternoon'),
(14,'Early afternoon'),
(15,'Mid-afternoon'),
(16,'Mid-afternoon'),
(17,'Late afternoon'),
(18,'Late afternoon'),
(19,'Early evening'),
(20,'Early evening'),
(21,'Late evening'),
(22,'Late evening'),
(23,'Late evening'),
(0,'Late at night'),
(1,'Late at night'),
(2,'Late at night'),
(3,'Toward morning'),
(4,'Toward morning'),
(5,'Toward morning');

--Check your table to see if you loaded it properly
select tod_name, listagg(hour,',') 
from time_of_day_lu
group by tod_name;

-- GRADE LESSON 4

--You have to run this grant or you won't be able to test your tasks while in SYSADMIN role
--this is true even if SYSADMIN owns the task!!
grant execute task on account to role SYSADMIN;

--Now you should be able to run the task, even if your role is set to SYSADMIN
execute task AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED;

--the SHOW command might come in handy to look at the task 
show tasks in account;

--you can also look at any task more in depth using DESCRIBE
describe task AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED;

create or replace task AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED
	warehouse=SAWH
	schedule='5 minute'
	as 
    INSERT INTO AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED 
    SELECT logs.ip_address
    , logs.user_login AS GAMER_NAME
    , logs.user_event AS GAME_EVENT_NAME
    , logs.datetime_iso8601 AS GAME_EVENT_UTC
    , city
    , region
    , country
    , timezone AS GAMER_LTZ_NAME
    , CONVERT_TIMEZONE('UTC',timezone,logs.datetime_iso8601) AS GAME_EVENT_LTZ
    , DAYNAME(GAME_EVENT_LTZ) AS DOW_NAME
    , TOD_NAME
    from AGS_GAME_AUDIENCE.RAW.LOGS logs
    JOIN IPINFO_GEOLOC.demo.location loc 
        ON IPINFO_GEOLOC.public.TO_JOIN_KEY(logs.ip_address) = loc.join_key
        AND IPINFO_GEOLOC.public.TO_INT(logs.ip_address) BETWEEN start_ip_int AND end_ip_int
    JOIN AGS_GAME_AUDIENCE.RAW.time_of_day_lu tod
        ON tod.hour = HOUR(GAME_EVENT_LTZ)
;

--make a note of how many rows you have in the table
select count(*)
from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;

--Run the task to load more rows
execute task AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED;

--check to see how many rows were added
select count(*)
from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;


--first we dump all the rows out of the table
truncate table ags_game_audience.enhanced.LOGS_ENHANCED;

--then we put them all back in
INSERT INTO ags_game_audience.enhanced.LOGS_ENHANCED (
SELECT logs.ip_address 
, logs.user_login as GAMER_NAME
, logs.user_event as GAME_EVENT_NAME
, logs.datetime_iso8601 as GAME_EVENT_UTC
, city
, region
, country
, timezone as GAMER_LTZ_NAME
, CONVERT_TIMEZONE( 'UTC',timezone,logs.datetime_iso8601) as game_event_ltz
, DAYNAME(game_event_ltz) as DOW_NAME
, TOD_NAME
from ags_game_audience.raw.LOGS logs
JOIN ipinfo_geoloc.demo.location loc 
ON ipinfo_geoloc.public.TO_JOIN_KEY(logs.ip_address) = loc.join_key
AND ipinfo_geoloc.public.TO_INT(logs.ip_address) 
BETWEEN start_ip_int AND end_ip_int
JOIN ags_game_audience.raw.TIME_OF_DAY_LU tod
ON HOUR(game_event_ltz) = tod.hour);


--clone the table to save this version as a backup
--since it holds the records from the UPDATED FEED file, we'll name it _UF
create table ags_game_audience.enhanced.LOGS_ENHANCED_UF 
clone ags_game_audience.enhanced.LOGS_ENHANCED;

select * from ags_game_audience.enhanced.LOGS_ENHANCED_UF;


MERGE INTO ENHANCED.LOGS_ENHANCED e
USING RAW.LOGS r
ON r.user_login = e.GAMER_NAME
AND r.datetime_iso8601 = e.GAME_EVENT_UTC
AND r.user_event = e.GAME_EVENT_NAME
WHEN MATCHED THEN
UPDATE SET IP_ADDRESS = 'Hey I updated matching rows!';

SELECT * FROM ENHANCED.LOGS_ENHANCED;

--let's truncate so we can start the load over again
-- remember we have that cloned back up so it's fine
truncate table AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;

create or replace task AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED
	warehouse=SAWH
	schedule='5 minute'
	as 
MERGE INTO ENHANCED.LOGS_ENHANCED e
USING (
    SELECT logs.ip_address 
    , logs.user_login as GAMER_NAME
    , logs.user_event as GAME_EVENT_NAME
    , logs.datetime_iso8601 as GAME_EVENT_UTC
    , city
    , region
    , country
    , timezone as GAMER_LTZ_NAME
    , CONVERT_TIMEZONE( 'UTC',timezone,logs.datetime_iso8601) as game_event_ltz
    , DAYNAME(game_event_ltz) as DOW_NAME
    , TOD_NAME
    from ags_game_audience.raw.LOGS logs
    JOIN ipinfo_geoloc.demo.location loc 
    ON ipinfo_geoloc.public.TO_JOIN_KEY(logs.ip_address) = loc.join_key
    AND ipinfo_geoloc.public.TO_INT(logs.ip_address) 
    BETWEEN start_ip_int AND end_ip_int
    JOIN ags_game_audience.raw.TIME_OF_DAY_LU tod
    ON HOUR(game_event_ltz) = tod.hour
  ) r
ON r.GAMER_NAME = e.GAMER_NAME
AND r.GAME_EVENT_UTC = e.GAME_EVENT_UTC
AND r.GAME_EVENT_NAME = e.GAME_EVENT_NAME
WHEN NOT MATCHED THEN
 INSERT (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME, GAME_EVENT_UTC, CITY, REGION, COUNTRY, GAMER_LTZ_NAME, GAME_EVENT_LTZ, DOW_NAME, TOD_NAME)
 VALUES (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME, GAME_EVENT_UTC, CITY, REGION, COUNTRY, GAMER_LTZ_NAME, GAME_EVENT_LTZ, DOW_NAME, TOD_NAME)
;

EXECUTE TASK AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED;


--Testing cycle for MERGE. Use these commands to make sure the Merge works as expected

--Write down the number of records in your table 
select * from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;

--Run the Merge a few times. No new rows should be added at this time 
EXECUTE TASK AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED;

--Check to see if your row count changed 
select * from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;

--Insert a test record into your Raw Table 
--You can change the user_event field each time to create "new" records 
--editing the ip_address or datetime_iso8601 can complicate things more than they need to 
--editing the user_login will make it harder to remove the fake records after you finish testing 
INSERT INTO ags_game_audience.raw.game_logs 
select PARSE_JSON('{"datetime_iso8601":"2025-01-01 00:00:00.000", "ip_address":"196.197.196.255", "user_event":"fake event", "user_login":"fake user"}');

--After inserting a new row, run the Merge again 
EXECUTE TASK AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED;

--Check to see if any rows were added 
select * from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;

--When you are confident your merge is working, you can delete the raw records 
delete from ags_game_audience.raw.game_logs where raw_log like '%fake user%';

--You should also delete the fake rows from the enhanced table
delete from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED
where gamer_name = 'fake user';

--Row count should be back to what it was in the beginning
select * from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED; 

---GRADE LESSON 5


CREATE OR REPLACE STAGE UNI_KISHORE_PIPELINE
URL = 's3://uni-kishore-pipeline';

SELECT current_timestamp();

LS @UNI_KISHORE_PIPELINE;

CREATE OR REPLACE TABLE RAW.PIPELINE_LOGS
LIKE RAW.GAME_LOGS;

COPY INTO PIPELINE_LOGS
FROM @UNI_KISHORE_PIPELINE
FILE_FORMAT = (format_name = FF_JSON_LOGS)
FORCE=FALSE;

select count(*) from pipeline_logs;

create or replace view AGS_GAME_AUDIENCE.RAW.PL_LOGS(
	USER_EVENT,
	USER_LOGIN,
	DATETIME_ISO8601,
	IP_ADDRESS,
	RAW_LOG
) as (
    SELECT 
        RAW_LOG:user_event::text AS user_event,
        RAW_LOG:user_login::text AS user_login,
        RAW_LOG:datetime_iso8601::timestamp_ntz AS datetime_iso8601,
        RAW_LOG:ip_address::text AS ip_address,
        RAW_LOG
    FROM PIPELINE_LOGS
    WHERE ip_address IS NOT NULL
);

select * from pl_logs;

create or replace task AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED
	-- warehouse=SAWH
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
	-- schedule='5 minute'
    -- after AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES
    schedule='5 minute'
	as 
-- MERGE INTO ENHANCED.LOGS_ENHANCED e
MERGE INTO ENHANCED.ED_PIPELINE_LOGS e
USING (
    SELECT logs.ip_address 
    , logs.user_login as GAMER_NAME
    , logs.user_event as GAME_EVENT_NAME
    , logs.datetime_iso8601 as GAME_EVENT_UTC
    , city
    , region
    , country
    , timezone as GAMER_LTZ_NAME
    , CONVERT_TIMEZONE( 'UTC',timezone,logs.datetime_iso8601) as game_event_ltz
    , DAYNAME(game_event_ltz) as DOW_NAME
    , TOD_NAME
    from ags_game_audience.raw.PL_LOGS logs
    JOIN ipinfo_geoloc.demo.location loc 
    ON ipinfo_geoloc.public.TO_JOIN_KEY(logs.ip_address) = loc.join_key
    AND ipinfo_geoloc.public.TO_INT(logs.ip_address) 
    BETWEEN start_ip_int AND end_ip_int
    JOIN ags_game_audience.raw.TIME_OF_DAY_LU tod
    ON HOUR(game_event_ltz) = tod.hour
  ) r
ON r.GAMER_NAME = e.GAMER_NAME
AND r.GAME_EVENT_UTC = e.GAME_EVENT_UTC
AND r.GAME_EVENT_NAME = e.GAME_EVENT_NAME
WHEN NOT MATCHED THEN
 INSERT (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME, GAME_EVENT_UTC, CITY, REGION, COUNTRY, GAMER_LTZ_NAME, GAME_EVENT_LTZ, DOW_NAME, TOD_NAME)
 VALUES (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME, GAME_EVENT_UTC, CITY, REGION, COUNTRY, GAMER_LTZ_NAME, GAME_EVENT_LTZ, DOW_NAME, TOD_NAME)
;


CREATE OR REPLACE TASK GET_NEW_FILES 
    -- warehouse=SAWH
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
	schedule='5 minute'
AS
COPY INTO PIPELINE_LOGS
FROM @UNI_KISHORE_PIPELINE
FILE_FORMAT = (format_name = FF_JSON_LOGS);


execute task get_new_files;

select count(*) from pipeline_logs;
select count(*) from pl_logs;

select *
from table(information_schema.task_history())
order by scheduled_time DESC;

truncate ENHANCED.LOGS_ENHANCED;

--Turning on a task is done with a RESUME command
alter task AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES resume;
alter task AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED resume;

show tasks;

--Keep this code handy for shutting down the tasks each day
alter task AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES suspend;
alter task AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED suspend;



use role accountadmin;
grant EXECUTE MANAGED TASK on account to SYSADMIN;

--switch back to sysadmin
use role sysadmin;

-- GRADE LESSON 6



CREATE TABLE ED_PIPELINE_LOGS AS
SELECT 
    METADATA$FILENAME as log_file_name --new metadata column
  , METADATA$FILE_ROW_NUMBER as log_file_row_id --new metadata column
  , current_timestamp(0) as load_ltz --new local time of load
  , get($1,'datetime_iso8601')::timestamp_ntz as DATETIME_ISO8601
  , get($1,'user_event')::text as USER_EVENT
  , get($1,'user_login')::text as USER_LOGIN
  , get($1,'ip_address')::text as IP_ADDRESS    
  FROM @AGS_GAME_AUDIENCE.RAW.UNI_KISHORE_PIPELINE
  (file_format => 'ff_json_logs');

--truncate the table rows that were input during the CTAS
truncate table ED_PIPELINE_LOGS;

--reload the table using your COPY INTO
COPY INTO ED_PIPELINE_LOGS
FROM (
    SELECT 
    METADATA$FILENAME as log_file_name 
  , METADATA$FILE_ROW_NUMBER as log_file_row_id 
  , current_timestamp(0) as load_ltz 
  , get($1,'datetime_iso8601')::timestamp_ntz as DATETIME_ISO8601
  , get($1,'user_event')::text as USER_EVENT
  , get($1,'user_login')::text as USER_LOGIN
  , get($1,'ip_address')::text as IP_ADDRESS    
  FROM @AGS_GAME_AUDIENCE.RAW.UNI_KISHORE_PIPELINE
)
file_format = (format_name = ff_json_logs);


-- no grading for LESSON 7


  
CREATE OR REPLACE PIPE GET_NEW_FILES
auto_ingest=true
aws_sns_topic='arn:aws:sns:us-west-2:321463406630:dngw_topic'
AS 
COPY INTO ED_PIPELINE_LOGS
FROM (
    SELECT 
    METADATA$FILENAME as log_file_name 
  , METADATA$FILE_ROW_NUMBER as log_file_row_id 
  , current_timestamp(0) as load_ltz 
  , get($1,'datetime_iso8601')::timestamp_ntz as DATETIME_ISO8601
  , get($1,'user_event')::text as USER_EVENT
  , get($1,'user_login')::text as USER_LOGIN
  , get($1,'ip_address')::text as IP_ADDRESS    
  FROM @AGS_GAME_AUDIENCE.RAW.UNI_KISHORE_PIPELINE
)
file_format = (format_name = ff_json_logs);




--create a stream that will keep track of changes to the table
create or replace stream ags_game_audience.raw.ed_cdc_stream 
on table AGS_GAME_AUDIENCE.RAW.ED_PIPELINE_LOGS;

--look at the stream you created
show streams;

--check to see if any changes are pending
select system$stream_has_data('ed_cdc_stream');

--query the stream
select * 
from ags_game_audience.raw.ed_cdc_stream;

--if your stream remains empty for more than 10 minutes, make sure your PIPE is running
select SYSTEM$PIPE_STATUS('GET_NEW_FILES');

--if you need to pause or unpause your pipe
--alter pipe GET_NEW_FILES set pipe_execution_paused = true;
--alter pipe GET_NEW_FILES set pipe_execution_paused = false;


--process the stream by using the rows in a merge 
MERGE INTO AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED e
USING (
        SELECT cdc.ip_address 
        , cdc.user_login as GAMER_NAME
        , cdc.user_event as GAME_EVENT_NAME
        , cdc.datetime_iso8601 as GAME_EVENT_UTC
        , city
        , region
        , country
        , timezone as GAMER_LTZ_NAME
        , CONVERT_TIMEZONE( 'UTC',timezone,cdc.datetime_iso8601) as game_event_ltz
        , DAYNAME(game_event_ltz) as DOW_NAME
        , TOD_NAME
        from ags_game_audience.raw.ed_cdc_stream cdc
        JOIN ipinfo_geoloc.demo.location loc 
        ON ipinfo_geoloc.public.TO_JOIN_KEY(cdc.ip_address) = loc.join_key
        AND ipinfo_geoloc.public.TO_INT(cdc.ip_address) 
        BETWEEN start_ip_int AND end_ip_int
        JOIN AGS_GAME_AUDIENCE.RAW.TIME_OF_DAY_LU tod
        ON HOUR(game_event_ltz) = tod.hour
      ) r
ON r.GAMER_NAME = e.GAMER_NAME
AND r.GAME_EVENT_UTC = e.GAME_EVENT_UTC
AND r.GAME_EVENT_NAME = e.GAME_EVENT_NAME 
WHEN NOT MATCHED THEN 
INSERT (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME
        , GAME_EVENT_UTC, CITY, REGION
        , COUNTRY, GAMER_LTZ_NAME, GAME_EVENT_LTZ
        , DOW_NAME, TOD_NAME)
        VALUES
        (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME
        , GAME_EVENT_UTC, CITY, REGION
        , COUNTRY, GAMER_LTZ_NAME, GAME_EVENT_LTZ
        , DOW_NAME, TOD_NAME);

--Did all the rows from the stream disappear? 
select * 
from ags_game_audience.raw.ed_cdc_stream; 


--turn off the other task (we won't need it anymore)
alter task AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED suspend;

--Create a new task that uses the MERGE you just tested
create or replace task AGS_GAME_AUDIENCE.RAW.CDC_LOAD_LOGS_ENHANCED
	USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE='XSMALL'
	SCHEDULE = '5 minutes'
    WHEN 
    system$stream_has_data('ed_cdc_stream')
	as 
MERGE INTO AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED e
USING (
        SELECT cdc.ip_address 
        , cdc.user_login as GAMER_NAME
        , cdc.user_event as GAME_EVENT_NAME
        , cdc.datetime_iso8601 as GAME_EVENT_UTC
        , city
        , region
        , country
        , timezone as GAMER_LTZ_NAME
        , CONVERT_TIMEZONE( 'UTC',timezone,cdc.datetime_iso8601) as game_event_ltz
        , DAYNAME(game_event_ltz) as DOW_NAME
        , TOD_NAME
        from ags_game_audience.raw.ed_cdc_stream cdc
        JOIN ipinfo_geoloc.demo.location loc 
        ON ipinfo_geoloc.public.TO_JOIN_KEY(cdc.ip_address) = loc.join_key
        AND ipinfo_geoloc.public.TO_INT(cdc.ip_address) 
        BETWEEN start_ip_int AND end_ip_int
        JOIN AGS_GAME_AUDIENCE.RAW.TIME_OF_DAY_LU tod
        ON HOUR(game_event_ltz) = tod.hour
      ) r
ON r.GAMER_NAME = e.GAMER_NAME
AND r.GAME_EVENT_UTC = e.GAME_EVENT_UTC
AND r.GAME_EVENT_NAME = e.GAME_EVENT_NAME 
WHEN NOT MATCHED THEN 
INSERT (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME
        , GAME_EVENT_UTC, CITY, REGION
        , COUNTRY, GAMER_LTZ_NAME, GAME_EVENT_LTZ
        , DOW_NAME, TOD_NAME)
        VALUES
        (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME
        , GAME_EVENT_UTC, CITY, REGION
        , COUNTRY, GAMER_LTZ_NAME, GAME_EVENT_LTZ
        , DOW_NAME, TOD_NAME);

--Resume the task so it is running
alter task AGS_GAME_AUDIENCE.RAW.CDC_LOAD_LOGS_ENHANCED resume;

truncate AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;
SELECT * FROM AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;

-- GRADE LESSON 8

show pipes;
alter pipe GET_NEW_FILES set pipe_execution_paused = true;
show tasks;
alter task CDC_LOAD_LOGS_ENHANCED suspend;


USE AGS_GAME_AUDIENCE;
CREATE SCHEMA CURATED;
DESCRIBE SCHEMA CURATED;


--the List Agg function can put both login and logout into a single column in a single row
-- if we don't have a logout, just one timestamp will appear
select GAMER_NAME
      , listagg(GAME_EVENT_LTZ,' / ') as login_and_logout
from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED 
group by gamer_name;


select GAMER_NAME
       ,game_event_ltz as login 
       ,lead(game_event_ltz) 
                OVER (
                    partition by GAMER_NAME 
                    order by GAME_EVENT_LTZ
                ) as logout
       ,coalesce(datediff('mi', login, logout),0) as game_session_length
from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED
order by game_session_length desc;


--We added a case statement to bucket the session lengths
select case when game_session_length < 10 then '< 10 mins'
            when game_session_length >= 10 and game_session_length < 20 then '10 to 19 mins'
            when game_session_length >= 20 and game_session_length < 30 then '20 to 29 mins'
            when game_session_length >= 30 and game_session_length < 40 then '30 to 39 mins'
            else '> 40 mins' 
            end as session_length
            ,tod_name
from (
select GAMER_NAME
       , tod_name
       ,game_event_ltz as login 
       ,lead(game_event_ltz) 
                OVER (
                    partition by GAMER_NAME 
                    order by GAME_EVENT_LTZ
                ) as logout
       ,coalesce(datediff('mi', login, logout),0) as game_session_length
from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED_UF)
where logout is not null;
