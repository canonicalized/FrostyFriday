USE WAREHOUSE COMPUTE_WH;
USE DATABASE FROSTYFRIDAY;
USE SCHEMA CHALLENGES;

CREATE OR REPLACE NOTIFICATION INTEGRATION EMAIL_NOTIFICATION_INTEGRATION
    TYPE=EMAIL
    ENABLED=TRUE
    ALLOWED_RECIPIENTS=('email@domain.com');
    
-- Create the alert
create or replace alert ALERT_CH_LONG_RUNNING_QUERIES
  warehouse = COMPUTE_WH
  schedule = '1 MINUTE'
if (
  exists (
    select *
    from table(SNOWFLAKE.INFORMATION_SCHEMA.QUERY_HISTORY())
    where EXECUTION_STATUS = 'RUNNING'
      and START_TIME <= current_timestamp() - interval '1 MINUTE'
  )
)
then
  call SYSTEM$SEND_EMAIL (
    'EMAIL_NOTIFICATION_INTEGRATION',
    'email@domain.com',
    'Alert: Long running query detected in Snowflake!',
    'Queries running for more than 1 minute in your Snowflake account!'
  )
;

-- Describe the alert
desc alert ALERT_CH_LONG_RUNNING_QUERIES;

-- Activate the alert, requiring the EXECUTE ALERT privilege on the account
alter alert ALERT_CH_LONG_RUNNING_QUERIES resume;

-- Keep awake
create or replace procedure KEEP_AWAKE(
  AWAKE_TIME_IN_MINUTES INT
)
  returns string null
  language python
  runtime_version = '3.8'
  packages = ('snowflake-snowpark-python')
  handler = 'keep_awake'
as
$$

# Import module for inbound Snowflake session
from snowflake.snowpark import session as snowpark_session

# Import other modules
import time

# Define handler function
def keep_awake(
      snowpark_session: snowpark_session
    , awake_time_in_minutes: int
  ):
  time.sleep(60*awake_time_in_minutes)
  return
$$
;

call KEEP_AWAKE(2);

-- Monitor the history of alerts sent
select *
from table(INFORMATION_SCHEMA.ALERT_HISTORY(
    scheduled_time_range_start => dateadd('hour',-1,current_timestamp()))
)
order by SCHEDULED_TIME desc
;

-- Disable the alert to avoid the inevitable spam going forwards
alter alert ALERT_CH_LONG_RUNNING_QUERIES suspend;
