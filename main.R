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

schemas <- dbGetQuery(conn,  'select "testing_db" as SERVER_NAME, TABLE_SCHEMA from (select distinct TABLE_SCHEMA FROM INFORMATION_SCHEMA.TABLES) schema_list') 

schemas

tables <- dbGetQuery(conn, 'select TABLE_SCHEMA as object, "has_table" as predicate, TABLE_NAME as subject from INFORMATION_SCHEMA.TABLES')

tables

columns <- dbGetQuery(conn, 'select TABLE_NAME as object, "has_column" as predicate, COLUMN_NAME as subject from INFORMATION_SCHEMA.COLUMNS')

columns
constraints <- dbGetQuery(conn, 'select REFERENCED_TABLE_SCHEMA, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME, CONSTRAINT_NAME, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME from INFORMATION_SCHEMA.KEY_COLUMN_USAGE') 


## Insert Triples nto SPARQL set 

### Constraints
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

constraints_construct  <- rdf()

pmap(list(constraints_refined$subject, constraints_refined$predicate, constraints_refined$object), rdf_add, rdf = constraints_construct)

constraints_construct

rdf_serialize(constraints_construct, "constraints_test.rdf", format = 'rdfxml')

### Schemas 

schemas_refined <- schemas %>%
	rowid_to_column("subject") %>%
	mutate(
	       subject = paste0("http://example.com/schemas#", subject)
	       , SCHEMA_NAME = paste0("http://example.com/schemas#", TABLE_SCHEMA)
	       , SERVER_NAME = paste0("http://example.com/servers#", SERVER_NAME)
	       )%>%
	select(subject, SERVER_NAME, SCHEMA_NAME) %>%
	pivot_longer(names_to = 'predicate', values_to = 'object', -subject) %>%
	mutate(predicate = paste0("http://example.com/schemas#", predicate))

schemas_refined

schemas_construct  <- rdf()

pmap(list(schemas_refined$subject, schemas_refined$predicate, schemas_refined$object), rdf_add, rdf = schemas_construct)

schemas_construct

rdf_serialize(schemas_construct, "schemas_test.rdf", format = 'rdfxml')



