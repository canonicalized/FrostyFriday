USE DATABASE AQ_CHICAGO;
USE SCHEMA RAW;

-- create or replace file format JSON_FORMAT
-- type = json;


-- create OR REPLACE stage GEOJSON
-- FILE_FORMAT = JSON_FORMAT;

ls @geojson;

-- read file contents
select 
    METADATA$FILENAME::STRING as FILE_NAME
  , METADATA$FILE_ROW_NUMBER as ROW_NUMBER
  , $1:features::VARIANT as CONTENTS
from @GEOJSON
  (file_format => 'JSON_FORMAT')
order by 
    FILE_NAME
  , ROW_NUMBER
;

-- Create a table in which to land the data
create or replace table RAW_DATA (
    FILE_NAME STRING
  , ROW_NUMBER INT
  , RAW_JSON VARIANT
)
;

-- Ingest the data
COPY INTO RAW_DATA
FROM (
  select 
    METADATA$FILENAME::STRING as FILE_NAME
  , METADATA$FILE_ROW_NUMBER as ROW_NUMBER
  , $1:features::VARIANT as CONTENTS
  from @GEOJSON
    (file_format => 'JSON_FORMAT')
);

-- --using staged data
-- SELECT  r.index, r.value
-- FROM @GEOJSON
-- ,TABLE(FLATTEN($1:features)) r;


-- create table with flattened data
CREATE OR REPLACE TABLE FLATTENED_DATA AS
    SELECT  r.index AS INDEX
        ,r.value:properties:"TITLE"::string as TITLE
        ,r.value:properties:"FromBreak"::int as FROM_BREAK
        ,r.value:properties:"ToBreak"::int as TO_BREAK
        ,r.value:properties:"AnalysisAr"::float as ANALYSIS_AREA
        , TO_GEOGRAPHY(r.value:geometry) AS geom
        , ST_ASWKT(TO_GEOGRAPHY(r.value:geometry)) AS wkt
    FROM RAW_DATA
    ,TABLE(FLATTEN(RAW_DATA.RAW_JSON)) r;

SELECT * FROM FLATTENED_DATA;









--chicago boundaries from geojson file - single row
USE DATABASE AQ_CHICAGO;
USE SCHEMA RAW;

create or replace file format JSON_FORMAT
type = json;


create OR REPLACE stage GEOJSON
FILE_FORMAT = JSON_FORMAT;

ls @geojson;

select to_geometry($1:features[0].geometry) as geometry from @GEOJSON;


create OR replace table chicago_boundaries(geom geography);

copy into chicago_boundaries
from 
(select to_geography($1:features[0].geometry) as geom from @GEOJSON)
file_format = (FORMAT_NAME = 'JSON_FORMAT')
PURGE = TRUE; -- purge to save space (the geojson file is pretty large)

CREATE OR REPLACE TABLE aq_chicago.prod.chicago_boundaries AS
select 1 as ID, GEOM, ST_ASWKT(GEOM) as WKT, ST_SIMPLIFY(GEOM, 2000) AS GEOM_SIMPL, ST_ASWKT(ST_SIMPLIFY(GEOM, 2000)) AS WKT_SIMPL, ST_CENTROID(GEOM) AS CENTROID
, ST_ASWKT(ST_CENTROID(GEOM)) AS WKT_CENTROID, ST_X(ST_CENTROID(GEOM)) AS LAT, ST_Y(ST_CENTROID(GEOM)) AS LONG
from aq_chicago.raw.chicago_boundaries;

SELECT ST_ASWKT(ST_CENTROID(GEOM)) AS WKT_CENTROID, ST_X(ST_CENTROID(GEOM)) AS LONG, ST_Y(ST_CENTROID(GEOM)) AS LAT FROM aq_chicago.raw.chicago_boundaries;

ALTER WAREHOUSE SAWH suspend;
