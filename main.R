# Main Process

source(here::here("R/packages.R"))


## Connect to SPARQL Server

d <- SPARQL(
	    url="localhost:3030/test_ds"
	    , query="SELECT * WHERE { ?s ?p ?o . } LIMIT 10"
	    , ns=c('time','<http://www.w3.org/2006/time#>')
)

print(d)

## Connect to MySQL Server

conn  <- dbConnect(MariaDB(), user = 'root', password = 'example', host =  '0.0.0.0', port = '3306')

dbListObjects(conn)

## Obtain relationship triples from schema

schemas <- dbGetQuery(conn,  'select "db_name" as object, "has_schema" as relation, TABLE_SCHEMA as predicate from (select distinct TABLE_SCHEMA FROM INFORMATION_SCHEMA.TABLES) schema_list') 

schemas

tables <- dbGetQuery(conn, 'select TABLE_SCHEMA as object, "has_table" as relation, TABLE_NAME as predicate from INFORMATION_SCHEMA.TABLES')

tables

columns <- dbGetQuery(conn, 'select TABLE_NAME as object, "has_column" as relation, COLUMN_NAME as predicate from INFORMATION_SCHEMA.COLUMNS')

columns

constraints_destination <- dbGetQuery(conn, 'select COLUMN_NAME as object, "is_constrained_by" as relation, CONSTRAINT_NAME as predicate from INFORMATION_SCHEMA.KEY_COLUMN_USAGE')

constraints_destination

constraints_source <- dbGetQuery(conn, 'select REFERENCED_COLUMN_NAME as object, "is_constraint_of" as relation, CONSTRAINT_NAME as predicate from INFORMATION_SCHEMA.KEY_COLUMN_USAGE where REFERENCED_COLUMN_NAME is not null')

constraints_source




