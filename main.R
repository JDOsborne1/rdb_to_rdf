# Main Process

source(here::here("R/packages.R"))
source(here::here("R/render_functions.R"))



## Connect to SPARQL Server

d <- SPARQL(
	    url="localhost:3030/test_ds"
	    , query="SELECT distinct ?p WHERE { ?s ?p ?o . }"
	    , ns=c(c('constraints','<http://example.com/constraints#>'), c('ex', 'http://example.com/'))
)

print(d)

## Connect to MySQL Server

conn  <- dbConnect(MariaDB(), user = 'root', password = 'example', host =  '0.0.0.0', port = '3306')

dbListObjects(conn)

## Obtain predicateship triples from schema

schemas <- dbGetQuery(conn,  'select "testing_db" as SERVER_NAME, TABLE_SCHEMA from (select distinct TABLE_SCHEMA FROM INFORMATION_SCHEMA.TABLES) schema_list') 

schemas

tables <- dbGetQuery(conn, 'select TABLE_SCHEMA, TABLE_NAME from INFORMATION_SCHEMA.TABLES')

tables

columns <- dbGetQuery(conn, 'select TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS')

columns                                 

constraints <- dbGetQuery(conn, 'select REFERENCED_TABLE_SCHEMA, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME, CONSTRAINT_NAME, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME from INFORMATION_SCHEMA.KEY_COLUMN_USAGE') 


## Insert Triples nto SPARQL set 

### Constraints
constraints_refined <- constraints %>%
	rowid_to_column("subject") %>%
	mutate(
	       subject = paste0("http://example.com/constraint#", subject)
	       , constrained_column = paste0("http://example.com/schema#", TABLE_SCHEMA, "/table#", TABLE_NAME ,"/column#", COLUMN_NAME)
	       , constraining_column = paste0("http://example.com/schema#", REFERENCED_TABLE_SCHEMA, "/table#", REFERENCED_TABLE_NAME ,"/column#", REFERENCED_COLUMN_NAME)
	       )%>%
	select(subject, constraining_column, constrained_column) %>%
	pivot_longer(names_to = 'predicate', values_to = 'object', -subject) %>%
	mutate(predicate = paste0("http://example.com/constraint#", predicate))

constraints_construct  <- rdf()

pmap(list(constraints_refined$subject, constraints_refined$predicate, constraints_refined$object), rdf_add, rdf = constraints_construct)

constraints_construct
	       

rdf_serialize(constraints_construct, "constraints_test.rdf", format = 'rdfxml')

### Schemas 

schemas_refined <- schemas %>%
	rowid_to_column("subject") %>%
	mutate(
	       subject = paste0("http://example.com/schema#", TABLE_SCHEMA)
	       , SERVER_LINK = paste0("http://example.com/server#", SERVER_NAME)
	       )%>%
	select(subject, SERVER_LINK, SCHEMA_NAME = TABLE_SCHEMA) %>%
	pivot_longer(names_to = 'predicate', values_to = 'object', -subject) %>%
	mutate(predicate = paste0("http://example.com/schema#", predicate))

schemas_refined

schemas_construct  <- rdf()

pmap(list(schemas_refined$subject, schemas_refined$predicate, schemas_refined$object), rdf_add, rdf = schemas_construct)

schemas_construct

rdf_serialize(schemas_construct, "schemas_test.rdf", format = 'rdfxml')

### Tables 

tables_refined <- tables %>%
	rowid_to_column("subject") %>%
	mutate(
	       subject = paste0("http://example.com/schema#", TABLE_SCHEMA, "/table#", TABLE_NAME)
	       , SCHEMA_LINK = paste0("http://example.com/schema#", TABLE_SCHEMA)
	       )%>%
	select(subject, TABLE_NAME, SCHEMA_LINK) %>%
	pivot_longer(names_to = 'predicate', values_to = 'object', -subject) %>%
	mutate(predicate = paste0("http://example.com/table#", predicate))

tables_refined

tables_construct  <- rdf()

pmap(list(tables_refined$subject, tables_refined$predicate, tables_refined$object), rdf_add, rdf = tables_construct)

tables_construct

rdf_serialize(tables_construct, "tables_test.rdf", format = 'rdfxml')


### columns 

columns_refined <- columns %>%
	rowid_to_column("subject") %>%
	mutate(
	       subject = paste0("http://example.com/schema#",TABLE_SCHEMA ,"/table#",TABLE_NAME ,"/column#", COLUMN_NAME)
	       , TABLE_LINK = paste0("http://example.com/schema#", TABLE_SCHEMA,  "/table#", TABLE_NAME)
	       )%>%
	select(subject, COLUMN_NAME, TABLE_LINK) %>%
	pivot_longer(names_to = 'predicate', values_to = 'object', -subject) %>%
	mutate(predicate = paste0("http://example.com/column#", predicate))

columns_refined

columns_construct  <- rdf()

pmap(list(columns_refined$subject, columns_refined$predicate, columns_refined$object), rdf_add, rdf = columns_construct)

columns_construct

rdf_serialize(columns_construct, "columns_test.rdf", format = 'rdfxml')

## Generate GraphViz for relational diagram


table_store <- schm_get_tables(.from_sparql_endpoint = 'localhost:3030/test_ds')

test_table <- pure_create_table_DOT(.using_table='TABLES_EXTENSIONS', .from_table_store = table_store)

pure_create_ERD_DOT(.using_tables = test_table) %>%
	 writeLines("test_tbl_2.txt")
## Generate Links
