USE WAREHOUSE COMPUTE_WH;
USE DATABASE FROSTYFRIDAY;
USE SCHEMA CHALLENGES;


-- Create the warehouses
create warehouse if not exists my_xsmall_wh 
    with warehouse_size = XSMALL
    auto_suspend = 120;
    
create warehouse if not exists my_small_wh 
    with warehouse_size = SMALL
    auto_suspend = 120;

-- Create the table
create or replace table week10
(
    date_time datetime,
    trans_amount double
);

-- Create the stage
create or replace stage week_10_frosty_stage
    url = 's3://frostyfridaychallenges/challenge_10/'
    file_format = CSV_FORMAT_H1;

SELECT $1, $2 FROM @week_10_frosty_stage;

LS @week_10_frosty_stage;

COPY INTO week10 FROM
(SELECT $1, $2 FROM @week_10_frosty_stage);

-- Create the stored procedure
create or replace procedure dynamic_warehouse_data_load(stage_name string, table_name string)
RETURNS string
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'main'
EXECUTE AS CALLER
AS
$$
def main(session,stage_name,table_name):
    create_stage_result = session.sql("list @" + stage_name).collect()
    result=[]
    for file in create_stage_result:
        name = "@" + stage_name + "/" + file[0].split('/')[-1]
        size = int(file[1])
        #result.append([name,size])
        if size > 10000:
            usewh = session.sql("USE WAREHOUSE my_small_wh").collect()
        else:
            usewh = session.sql("USE WAREHOUSE my_xsmall_wh").collect()
        copy = session.sql("copy into " + table_name + " from " + name).collect()    

    result = session.sql("select count(*) from " + table_name).collect()
    
    tbl = session.table(table_name)

    count = str(tbl.count()) + " rows were added"
    
    return count
$$;

-- Call the stored procedure.
call dynamic_warehouse_data_load('week_10_frosty_stage', 'week10');


create or replace procedure dynamic_warehouse_data_load_sql(stage_name string, table_name string)
returns varchar
language sql
execute as caller
as
  declare
    -- Constants
    C_XSMALL_WH varchar default 'my_xsmall_wh';
    C_SMALL_WH  varchar default 'my_small_wh';
    C_FILE_SIZE_LIMIT number default 10000;
    
    -- Variables
    v_list_command varchar default 'list @' || stage_name;
    res_files resultset;
    v_warehouse_name varchar;
    v_use_wh_command varchar;
    v_file_name varchar;
    v_copy_command varchar;
    res_copy resultset;
    n_total_rows_loaded number default 0;
    
  begin
    -- Get list of files into resultset
    res_files := (execute immediate v_list_command);
    
    -- Define cursor for the resultset
    let c_files cursor for res_files;
    
    -- Loop the files
    for rec_file in c_files do

      -- Get the warehouse name to be used
      if ( rec_file."size" >= C_FILE_SIZE_LIMIT ) then
        v_warehouse_name := C_SMALL_WH;
      else
        v_warehouse_name := C_XSMALL_WH;
      end if;
      
      -- Set the warehouse
      v_use_wh_command := 'use warehouse ' || v_warehouse_name;
      execute immediate v_use_wh_command;
      
      -- Get the file name part from the result of list-command, eg. s3://frostyfridaychallenges/challenge_10/2022-07-01.csv
      v_file_name := split_part(rec_file."name", '/', 5);
      
      -- Load the data
      v_copy_command := 'copy into ' || table_name || ' from @' || stage_name || '/' || v_file_name;
      res_copy := (execute immediate v_copy_command);
      
      -- Define cursor for the resultset
      let c_res_copy cursor for res_copy;
    
      -- Loop the ONE result row and add to total rows loaded -counter.
      for rec_res_copy in c_res_copy do
        n_total_rows_loaded := n_total_rows_loaded + rec_res_copy."rows_loaded";
      end for;
      
    end for;
    
    return n_total_rows_loaded || ' rows were added';

  end;

call dynamic_warehouse_data_load('week_10_frosty_stage', 'week10');


select * from table(information_schema.query_history_by_session()) order by start_time DESC;
