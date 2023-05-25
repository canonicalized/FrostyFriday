USE DATABASE FROSTYFRIDAY;
USE SCHEMA CHALLENGES;

CREATE OR REPLACE STAGE S3_FF_WEEK6
    URL = 's3://frostyfridaychallenges/challenge_6/';

CREATE OR REPLACE FILE FORMAT CSV_FORMAT_H1
TYPE='CSV'
FIELD_DELIMITER=','
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"';



-- NATIONS/REGIONS

CREATE OR REPLACE TABLE WEEK6_NATIONS_REGIONS_POINTS (
    nation_or_region_name VARCHAR
    ,type VARCHAR
    ,sequence_num INT
    ,longitude NUMBER(9,6)
    ,latitude NUMBER(9,6)
    ,part INT
);

COPY INTO WEEK6_NATIONS_REGIONS_POINTS FROM
(
    SELECT $1 AS nation_or_region_name, $2 AS type, $3 AS sequence_num, $4 AS longitude, $5 AS latitude, $6 AS part
    FROM @S3_FF_WEEK6/nations_and_regions.csv
    (FILE_FORMAT => 'CSV_FORMAT_H1')
);

SELECT * FROM WEEK6_NATIONS_REGIONS_POINTS;

CREATE OR REPLACE TABLE WEEK6_NATIONS_REGIONS_POLYGONS AS
WITH 
    nr0 AS (
        SELECT 
        NATION_OR_REGION_NAME, TYPE, PART,
        TO_GEOGRAPHY(
              'POLYGON((' || 
                  LISTAGG(longitude || ' ' || latitude, ',') WITHIN GROUP (ORDER BY sequence_num) ||
              '))'
        ) AS polygon
        FROM WEEK6_NATIONS_REGIONS_POINTS
        GROUP BY NATION_OR_REGION_NAME, TYPE, PART
     ),
    
    nr1 AS ( 
        SELECT NATION_OR_REGION_NAME, TYPE, ST_COLLECT(polygon) AS geo 
        FROM nr0
        GROUP BY NATION_OR_REGION_NAME, TYPE
    )

SELECT * FROM nr1;

SELECT NATION_OR_REGION_NAME, GEO FROM WEEK6_NATIONS_REGIONS_POLYGONS;



-- CONSTITUENCIES

CREATE OR REPLACE TABLE WEEK6_CONSTITUENCY_POINTS (
    constituency VARCHAR
    ,sequence_num INT
    ,longitude NUMBER(9,6)
    ,latitude NUMBER(9,6)
    ,part INT
);

COPY INTO WEEK6_CONSTITUENCY_POINTS FROM
(
    SELECT $1 AS constituency,$2 AS sequence_num,$3 AS longitude,$4 AS latitude,$5 AS part
    FROM @S3_FF_WEEK6/westminster_constituency_points.csv
    (FILE_FORMAT => 'CSV_FORMAT_H1')
);

SELECT * FROM WEEK6_CONSTITUENCY_POINTS;

CREATE OR REPLACE TABLE WEEK6_CONSTITUENCY_POLYGONS AS
WITH 
    c0 AS (
        SELECT 
        constituency, part,
        TO_GEOGRAPHY(
              'POLYGON((' || 
                  LISTAGG(longitude || ' ' || latitude, ',') WITHIN GROUP (ORDER BY sequence_num) ||
              '))'
        ) AS polygon
        FROM WEEK6_CONSTITUENCY_POINTS
        GROUP BY constituency, part
     ),
    
    c1 AS ( 
        SELECT constituency, ST_COLLECT(polygon) AS geo 
        FROM c0 
        GROUP BY constituency
    )

SELECT * FROM c1;

SELECT * FROM WEEK6_CONSTITUENCY_POLYGONS;



-- INTERSECTIONS

SELECT nr.NATION_OR_REGION_NAME, COUNT(c.constituency) AS INTERSECTING_CONSTITUENCIES
FROM WEEK6_NATIONS_REGIONS_POLYGONS nr 
LEFT JOIN WEEK6_CONSTITUENCY_POLYGONS c ON ST_INTERSECTS(nr.GEO,c.geo)
GROUP BY 1
ORDER BY INTERSECTING_CONSTITUENCIES DESC;
