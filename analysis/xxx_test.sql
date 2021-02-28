/*

### psql documentation https://www.postgresql.org/docs/13/app-psql.html
### list of postgres tools https://www.postgresql.org/docs/13/reference-client.html

export PGPASSWORD=Hunter2

psql \
    --host db \
    --port 5432 \
    --username gowerc \
    aoe

### Get table structure

pg_dump \
    --table=players \
    --host=db \
    --port=5432 \
    --username=postgres \
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



create table matches2 as select * from matches; 
drop table matches2;






delete from players
where match_id in (
    select match_id from matches where started >= 1613843838
) ; 

Delete from matches where started >= 1613843838; 





-- Create some test data;
CREATE  TABLE tab1 (
    id integer PRIMARY KEY,
    val text NOT NULL
);

CREATE  TABLE tab2 (
    val text NOT NULL,      -- Note change in column order
    id integer PRIMARY KEY
);


INSERT INTO tab1 (id, val) VALUES
    (1, 'fred'),
    (2, 'bob');

INSERT INTO tab2 (id, val) VALUES
    (2, 'bob'),
    (3, 'ann'),
    (4, 'steve');


select * from tab1;


drop table players;
drop table matches, tab1, tab2, temp;



INSERT into match_players
select * from matches;


