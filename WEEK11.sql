USE WAREHOUSE COMPUTE_WH;
USE DATABASE FROSTYFRIDAY;
USE SCHEMA CHALLENGES;

-- Create the stage that points at the data.
create or replace stage 
    week_11_frosty_stage url = 's3://frostyfridaychallenges/challenge_11/' 
    file_format = CSV_FORMAT_H1;
-- LIST @week_11_frosty_stage;
-- DESCRIBE STAGE week_11_frosty_stage;

-- Create the table as a CTAS statement.
create or replace table frostyfriday.challenges.week11 as
select
    m.$1 as milking_datetime,
    m.$2 as cow_number,
    m.$3 as fat_percentage,
    m.$4 as farm_code,
    m.$5 as centrifuge_start_time,
    m.$6 as centrifuge_end_time,
    m.$7 as centrifuge_kwph,
    m.$8 as centrifuge_electricity_used,
    m.$9 as centrifuge_processing_time,
    m.$10 as task_used
from
    @week_11_frosty_stage (
        file_format => 'CSV_FORMAT_H1',
        pattern => '.*milk_data.*[.]csv'
    ) m;
    
SELECT * FROM WEEK11 WHERE FAT_PERCENTAGE = 3;

-- TASK 1: Remove all the centrifuge dates and centrifuge kwph and replace them with NULLs WHERE fat = 3.
-- Add note to task_used.
create or replace task whole_milk_updates schedule = '1400 minutes' as
    UPDATE
        WEEK11
    SET
        CENTRIFUGE_START_TIME = NULL,
        CENTRIFUGE_END_TIME = NULL,
        CENTRIFUGE_KWPH = NULL,
        TASK_USED = concat(
            SYSTEM$CURRENT_USER_TASK_NAME(),
            ' at ',
            CURRENT_TIMESTAMP()::STRING
        )
    WHERE
        fat_percentage = 3;

-- TASK 2: Calculate centrifuge processing time (difference between start and end time) WHERE fat != 3.
-- Add note to task_used.
create or replace task skim_milk_updates
    after
        frostyfriday.challenges.whole_milk_updates as
    UPDATE
        WEEK11
    SET
        centrifuge_processing_time = timediff(
            'minute',
            CENTRIFUGE_START_TIME,
            CENTRIFUGE_END_TIME
        ),
        TASK_USED = concat(
            SYSTEM$CURRENT_USER_TASK_NAME(),
            ' at ',
            CURRENT_TIMESTAMP()::STRING
        )
    WHERE
        fat_percentage != 3;

-- Enable the child task, otherwise it will be ignored
alter task skim_milk_updates resume;

SHOW TASKS;

-- Manually execute the task.
execute task whole_milk_updates;

-- View task history
select *
from table(information_schema.task_history())
order by scheduled_time DESC;

-- Check that the data looks as it should.
select * from week11;
    
-- Check that the numbers are correct.
select
    task_used, count(*) as row_count
from week11
group by task_used;
