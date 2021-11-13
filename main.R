# Main Process

source(here::here("R/packages.R"))


## Connect to SPARQL Server

d <- SPARQL(
	    url="localhost:3030/test_ds"
	    , query="SELECT * WHERE { ?s ?p ?o . } LIMIT 10"
	    , ns=c(c('constraints','<http://example.com/constraints#>'), c('ex', 'http://example.com/'))
)

print(d)

## Connect to MySQL Server

conn  <- dbConnect(MariaDB(), user = 'root', password = 'example', host =  '0.0.0.0', port = '3306')

dbListObjects(conn)

## Obtain predicateship triples from schema

schemas <- dbGetQuery(conn,  'select "db_name" as object, "has_schema" as predicate, TABLE_SCHEMA as subject from (select distinct TABLE_SCHEMA FROM INFORMATION_SCHEMA.TABLES) schema_list') 

schemas

tables <- dbGetQuery(conn, 'select TABLE_SCHEMA as object, "has_table" as predicate, TABLE_NAME as subject from INFORMATION_SCHEMA.TABLES')

tables

columns <- dbGetQuery(conn, 'select TABLE_NAME as object, "has_column" as predicate, COLUMN_NAME as subject from INFORMATION_SCHEMA.COLUMNS')

columns

constraints_destination <- dbGetQuery(conn, 'select COLUMN_NAME as object, "is_constrained_by" as predicate, CONSTRAINT_NAME as subject from INFORMATION_SCHEMA.KEY_COLUMN_USAGE')

constraints_destination

constraints_source <- dbGetQuery(conn, 'select REFERENCED_COLUMN_NAME as object, "is_constraint_of" as predicate, CONSTRAINT_NAME as subject from INFORMATION_SCHEMA.KEY_COLUMN_USAGE where REFERENCED_COLUMN_NAME is not null')

constraints_source

constraints <- dbGetQuery(conn, 'select REFERENCED_TABLE_SCHEMA, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME, CONSTRAINT_NAME, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME from INFORMATION_SCHEMA.KEY_COLUMN_USAGE') 

dbGetQuery(conn, 'select * from INFORMATION_SCHEMA.KEY_COLUMN_USAGE limit 1')

constraints_refined <- constraints %>%
	rowid_to_column("subject") %>%
	mutate(
	       subject = paste0("http://example.com/constraints#", subject)
	       , constrained_column = paste0("http://example.com/", TABLE_SCHEMA, "/", TABLE_NAME ,"/", COLUMN_NAME)
	       , constraining_column = paste0("http://example.com/", REFERENCED_TABLE_SCHEMA, "/", REFERENCED_TABLE_NAME ,"/", REFERENCED_COLUMN_NAME)
	       )%>%
	select(subject, constraining_column, constrained_column) %>%
	pivot_longer(names_to = 'predicate', values_to = 'object', -subject) %>%
	mutate(predicate = paste0("http://example.com/constraints#", predicate))

## Insert Triples nto SPARQL set 

constraints_construct  <- rdf()

pmap(list(constraints_refined$subject, constraints_refined$predicate, constraints_refined$object), rdf_add, rdf = constraints_construct)

constraints_construct

rdf_serialize(constraints_construct, "constraints_test.rdf", format = 'rdfxml')
