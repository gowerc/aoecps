/*

### psql documentation https://www.postgresql.org/docs/13/app-psql.html
### list of postgres tools https://www.postgresql.org/docs/13/reference-client.html

export PGPASSWORD=mypassword

psql \
    --host db \
    --port 5432 \
    --username gowerc \
    aoe

### Get table structure

pg_dump \
    --table=matches2 \
    --host=db \
    --port=5432 \
    --username=gowerc \
    --dbname=aoe \
    --schema-only


*/

-- Disable the use of "more" to show long outputs
\pset pager off

-- list tables
\dt  

-- list tables with more info ;
\dt+

-- list columns in a given table
\d matches
\d+ matches


SHOW CREATE TABLE matches;

select a.won, a.civ
from players a
limit 10;





select * from matches2;

select max(started) as maxstart from matches2;
