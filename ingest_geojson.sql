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
