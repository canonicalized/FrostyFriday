USE WAREHOUSE SAWH;
USE DATABASE FROSTYFRIDAY;
USE SCHEMA CHALLENGES;

create or replace stage week56_stage
    url='s3://frostyfridaychallenges/challenge_56/'
    -- DIRECTORY = (ENABLE = TRUE)
;

LIST @WEEK56_STAGE;

CREATE OR REPLACE TABLE WEEK56 (id NUMBER, reaction VARCHAR);

COPY INTO WEEK56 FROM 
(
    SELECT $1::NUMBER AS ID
         , TRIM($2)::VARCHAR AS REACTION 
    FROM @week56_stage
    (FILE_FORMAT => 'csv_format_h1')
);

SELECT * FROM WEEK56;

SELECT DISTINCT(REACTION) FROM WEEK56;


CREATE OR REPLACE FUNCTION emoji_to_text(emoji STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
handler = 'main'
AS
$$
def main(emoji):
    emoji_dict = {
    '😀': ':grinning:',
    '☹️': ':sad:',
    '🚀': ':rocket:',
    '😑': ':neutral:'
    }
    return emoji_dict.get(emoji, '')
$$;


SELECT *, emoji_to_text(REACTION) FROM WEEK56;

CREATE OR REPLACE TABLE WEEK56_EMOJIS AS
SELECT DISTINCT REACTION as emoji, emoji_to_text(REACTION) as emoji_text FROM WEEK56;

SELECT * FROM WEEK56_EMOJIS;


-- CREATE OR REPLACE NOTIFICATION INTEGRATION EMAIL_NOTIFICATION_INTEGRATION
--     TYPE=EMAIL
--     ENABLED=TRUE
--     ALLOWED_RECIPIENTS=('email@domain.com');
    
-- Create the alert
create or replace alert ALERT_NEW_EMOJI
  warehouse = SAWH
  schedule = 'USING CRON 0 10 * * 1 UTC' --10AM every Monday
  -- schedule = '1 minute'
if (
  exists (
    select DISTINCT REACTION from WEEK56 d
    LEFT OUTER JOIN WEEK56_EMOJIS e ON d.reaction = e.emoji
    WHERE e.emoji IS NULL
  )
)
then
  call SYSTEM$SEND_EMAIL (
    'EMAIL_NOTIFICATION_INTEGRATION',
    'email@domain.com',
    'Alert: New emojis detected in Snowflake!',
    'There are new emojis in your data.'
  )
;

-- Describe the alert
desc alert ALERT_NEW_EMOJI;

-- Activate the alert, requiring the EXECUTE ALERT privilege on the account
GRANT EXECUTE ALERT ON ACCOUNT TO ROLE SYSADMIN; -- run as ACCOUNTADMIN
alter alert ALERT_NEW_EMOJI resume;



-- Monitor the history of alerts sent
select *
from table(INFORMATION_SCHEMA.ALERT_HISTORY(
    scheduled_time_range_start => dateadd('hour',-1,current_timestamp()))
)
order by SCHEDULED_TIME desc
;

-- Disable the alert to avoid the inevitable spam going forwards
alter alert ALERT_CH_LONG_RUNNING_QUERIES suspend;
