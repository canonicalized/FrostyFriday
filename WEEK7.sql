--TAGS Require Enterprise edition of Snowflake

USE WAREHOUSE COMPUTE_WH;
USE DATABASE FROSTYFRIDAY;
USE SCHEMA CHALLENGES;

create or replace table week7_villain_information (
	id INT,
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	email VARCHAR(50),
	Alter_Ego VARCHAR(50)
);
insert into week7_villain_information (id, first_name, last_name, email, Alter_Ego) values (1, 'Chrissy', 'Riches', 'criches0@ning.com', 'Waterbuck, defassa');
insert into week7_villain_information (id, first_name, last_name, email, Alter_Ego) values (2, 'Libbie', 'Fargher', 'lfargher1@vistaprint.com', 'Ibis, puna');
insert into week7_villain_information (id, first_name, last_name, email, Alter_Ego) values (3, 'Becka', 'Attack', 'battack2@altervista.org', 'Falcon, prairie');
insert into week7_villain_information (id, first_name, last_name, email, Alter_Ego) values (4, 'Euphemia', 'Whale', 'ewhale3@mozilla.org', 'Egyptian goose');
insert into week7_villain_information (id, first_name, last_name, email, Alter_Ego) values (5, 'Dixie', 'Bemlott', 'dbemlott4@moonfruit.com', 'Eagle, long-crested hawk');
insert into week7_villain_information (id, first_name, last_name, email, Alter_Ego) values (6, 'Giffard', 'Prendergast', 'gprendergast5@odnoklassniki.ru', 'Armadillo, seven-banded');
insert into week7_villain_information (id, first_name, last_name, email, Alter_Ego) values (7, 'Esmaria', 'Anthonies', 'eanthonies6@biblegateway.com', 'Cat, european wild');
insert into week7_villain_information (id, first_name, last_name, email, Alter_Ego) values (8, 'Celine', 'Fotitt', 'cfotitt7@baidu.com', 'Clark''s nutcracker');
insert into week7_villain_information (id, first_name, last_name, email, Alter_Ego) values (9, 'Leopold', 'Axton', 'laxton8@mac.com', 'Defassa waterbuck');
insert into week7_villain_information (id, first_name, last_name, email, Alter_Ego) values (10, 'Tadeas', 'Thorouggood', 'tthorouggood9@va.gov', 'Armadillo, nine-banded');

create or replace table week7_monster_information (
	id INT,
	monster VARCHAR(50),
	hideout_location VARCHAR(50)
);

insert into week7_monster_information (id, monster, hideout_location) values (1, 'Northern elephant seal', 'Huangban');
insert into week7_monster_information (id, monster, hideout_location) values (2, 'Paddy heron (unidentified)', 'Várzea Paulista');
insert into week7_monster_information (id, monster, hideout_location) values (3, 'Australian brush turkey', 'Adelaide Mail Centre');
insert into week7_monster_information (id, monster, hideout_location) values (4, 'Gecko, tokay', 'Tafí Viejo');
insert into week7_monster_information (id, monster, hideout_location) values (5, 'Robin, white-throated', 'Turośń Kościelna');
insert into week7_monster_information (id, monster, hideout_location) values (6, 'Goose, andean', 'Berezovo');
insert into week7_monster_information (id, monster, hideout_location) values (7, 'Puku', 'Mayskiy');
insert into week7_monster_information (id, monster, hideout_location) values (8, 'Frilled lizard', 'Fort Lauderdale');
insert into week7_monster_information (id, monster, hideout_location) values (9, 'Yellow-necked spurfowl', 'Sezemice');
insert into week7_monster_information (id, monster, hideout_location) values (10, 'Agouti', 'Najd al Jumā‘ī');


create table week7_weapon_storage_location (
	id INT,
	created_by VARCHAR(50),
	location VARCHAR(50),
	catch_phrase VARCHAR(50),
	weapon VARCHAR(50)
);

insert into week7_weapon_storage_location (id, created_by, location, catch_phrase, weapon) 
    values (1, 'Ullrich-Gerhold', 'Mazatenango', 'Assimilated object-oriented extranet', 'Fintone');
insert into week7_weapon_storage_location (id, created_by, location, catch_phrase, weapon) 
    values (2, 'Olson-Lindgren', 'Dvorichna', 'Switchable demand-driven knowledge user', 'Andalax');
insert into week7_weapon_storage_location (id, created_by, location, catch_phrase, weapon) 
    values (3, 'Rodriguez, Flatley and Fritsch', 'Palmira', 'Persevering directional encoding', 'Toughjoyfax');
insert into week7_weapon_storage_location (id, created_by, location, catch_phrase, weapon) 
    values (4, 'Conn-Douglas', 'Rukem', 'Robust tangible Graphical User Interface', 'Flowdesk');
insert into week7_weapon_storage_location (id, created_by, location, catch_phrase, weapon) 
    values (5, 'Huel, Hettinger and Terry', 'Bulawin', 'Multi-channelled radical knowledge user', 'Y-Solowarm');
insert into week7_weapon_storage_location (id, created_by, location, catch_phrase, weapon) 
    values (6, 'Torphy, Ritchie and Lakin', 'Wang Sai Phun', 'Self-enabling client-driven project', 'Alphazap');
insert into week7_weapon_storage_location (id, created_by, location, catch_phrase, weapon) 
    values (7, 'Carroll and Sons', 'Digne-les-Bains', 'Profound radical benchmark', 'Stronghold');
insert into week7_weapon_storage_location (id, created_by, location, catch_phrase, weapon) 
    values (8, 'Hane, Breitenberg and Schoen', 'Huangbu', 'Function-based client-server encoding', 'Asoka');
insert into week7_weapon_storage_location (id, created_by, location, catch_phrase, weapon) 
    values (9, 'Ledner and Sons', 'Bukal Sur', 'Visionary eco-centric budgetary management', 'Ronstring');
insert into week7_weapon_storage_location (id, created_by, location, catch_phrase, weapon) 
    values (10, 'Will-Thiel', 'Zafar', 'Robust even-keeled algorithm', 'Tin');
    


SELECT * FROM snowflake.account_usage.copy_history;
  
    
--Create Tags
create or replace tag security_class comment = 'sensitive data';

--Apply tags
alter table week7_villain_information set tag security_class = 'Level Super Secret A+++++++';
alter table week7_monster_information set tag security_class = 'Level B';
alter table week7_weapon_storage_location set tag security_class = 'Level Super Secret A+++++++';

--Create Roles
create role user1;
create role user2;
create role user3;

--Assign Roles to yourself with all needed privileges
grant role user1 to role accountadmin;
grant USAGE  on warehouse COMPUTE_WH to role user1;
grant usage on database FROSTYFRIDAY to role user1;
grant usage on all schemas in database FROSTYFRIDAY to role user1;
grant select on all tables in database FROSTYFRIDAY to role user1;

grant role user2 to role accountadmin;
grant USAGE  on warehouse COMPUTE_WH to role user2;
grant usage on database FROSTYFRIDAY to role user2;
grant usage on all schemas in database FROSTYFRIDAY to role user2;
grant select on all tables in database FROSTYFRIDAY to role user2;

grant role user3 to role accountadmin;
grant USAGE  on warehouse COMPUTE_WH to role user3;
grant usage on database FROSTYFRIDAY to role user3;
grant usage on all schemas in database FROSTYFRIDAY to role user3;
grant select on all tables in database FROSTYFRIDAY to role user3;

--Queries to build history
use role user1;
select * from week7_villain_information;

use role user2;
select * from week7_monster_information;

use role user3;
select * from week7_weapon_storage_location;



WITH access_hist AS (
  select query_id
       , user_name
       , f1.value:"objectName"::string as object_full_name
       , split_part(object_full_name,'.',1) as db_name
       , split_part(object_full_name,'.',2) as schema_name
       , split_part(object_full_name,'.',3) as object_name
  from snowflake.account_usage.access_history
     , lateral flatten(base_objects_accessed) f1
  where f1.value:"objectName"::string like 'FROSTYFRIDAY.CHALLENGES.WEEK7%'
  and f1.value:"objectDomain"::string = 'Table'
  and query_start_time >= dateadd('day', -1, current_timestamp())
),

tagged_tables AS (
  select tag_name
       , tag_value
       , object_database
       , object_schema
       , object_name
  from snowflake.account_usage.tag_references
  where tag_name = 'SECURITY_CLASS'
  and tag_value = 'Level Super Secret A+++++++'
),

query_hist AS (
  select query_id
       , user_name
       , role_name
  from snowflake.account_usage.query_history
  where start_time >= dateadd('day', -1, current_timestamp())
)

select t.tag_name
     , t.tag_value
     , min(q.query_id)
     , a.object_full_name
     , q.role_name
from tagged_tables t
inner join access_hist a on a.object_name = t.object_name
inner join query_hist q on q.query_id = a.query_id
group by t.tag_name
     , t.tag_value
     , a.object_full_name
     , q.role_name;
