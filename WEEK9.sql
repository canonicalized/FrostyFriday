USE WAREHOUSE COMPUTE_WH;
USE DATABASE FROSTYFRIDAY;
USE SCHEMA CHALLENGES;

--CREATE DATA
CREATE OR REPLACE TABLE data_to_be_masked(first_name varchar, last_name varchar,hero_name varchar);
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Eveleen', 'Danzelman','The Quiet Antman');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Harlie', 'Filipowicz','The Yellow Vulture');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Mozes', 'McWhin','The Broken Shaman');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Horatio', 'Hamshere','The Quiet Charmer');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Julianna', 'Pellington','Professor Ancient Spectacle');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Grenville', 'Southouse','Fire Wonder');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Analise', 'Beards','Purple Fighter');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Darnell', 'Bims','Mister Majestic Mothman');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Micky', 'Shillan','Switcher');
INSERT INTO data_to_be_masked (first_name, last_name, hero_name) VALUES ('Ware', 'Ledstone','Optimo');

--CREATE ROLE
CREATE ROLE foo1;

GRANT ROLE foo1 TO USER canonicalized;
grant USAGE  on warehouse COMPUTE_WH to role foo1;
grant usage on database FROSTYFRIDAY to role foo1;
grant usage on all schemas in database FROSTYFRIDAY to role foo1;
grant select on all tables in database FROSTYFRIDAY to role foo1;

CREATE ROLE foo2;
GRANT ROLE foo2 TO USER canonicalized;
grant USAGE  on warehouse COMPUTE_WH to role foo2;
grant usage on database FROSTYFRIDAY to role foo2;
grant usage on all schemas in database FROSTYFRIDAY to role foo2;
grant select on all tables in database FROSTYFRIDAY to role foo2;
  

create or replace tag sensitive_data allowed_values 'fname', 'lname';

alter table data_to_be_masked modify column
 first_name set tag sensitive_data = 'fname'
,last_name  set tag sensitive_data = 'lname'
;

create or replace masking policy sensitive_data_tag_string as (val string) returns string ->
  case
    when system$get_tag_on_current_column('sensitive_data')='fname' and (is_role_in_session('FOO1') or is_role_in_session('FOO2')) then val
    when system$get_tag_on_current_column('sensitive_data')='lname' and is_role_in_session('FOO2') then val
    else repeat('*',6)
  end
;

alter tag sensitive_data set masking policy sensitive_data_tag_string;

use role accountadmin;
select * from data_to_be_masked;

use role foo1;
select * from data_to_be_masked;

use role foo2;
select * from data_to_be_masked;


