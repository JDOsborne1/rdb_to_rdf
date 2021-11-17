## RDF Constructor Functions

### Functions which abstract the process of generating the RDF triples of a given kind of relationship


schm_construct_rdf_of_schemas <- function(.in){
	schemas <- dbGetQuery(.in,  'select "testing_db" as SERVER_NAME, TABLE_SCHEMA from (select distinct TABLE_SCHEMA FROM INFORMATION_SCHEMA.TABLES) schema_list') 

schemas_refined <- schemas %>%
	rowid_to_column("subject") %>%
	mutate(
	       subject = paste0("http://example.com/schema#", TABLE_SCHEMA)
	       , SERVER_LINK = paste0("http://example.com/server#", SERVER_NAME)
	       )%>%
	select(subject, SERVER_LINK, SCHEMA_NAME = TABLE_SCHEMA) %>%
	pivot_longer(names_to = 'predicate', values_to = 'object', -subject) %>%
	mutate(predicate = paste0("http://example.com/schema#", predicate))

schemas_construct  <- rdf()

pmap(list(schemas_refined$subject, schemas_refined$predicate, schemas_refined$object), rdf_add, rdf = schemas_construct)

schemas_construct

}


schm_construct_rdf_of_tables <- function(.in){

	tables <- dbGetQuery(.in, 'select TABLE_SCHEMA, TABLE_NAME from INFORMATION_SCHEMA.TABLES')

tables_refined <- tables %>%
	rowid_to_column("subject") %>%
	mutate(
	       subject = paste0("http://example.com/schema#", TABLE_SCHEMA, "/table#", TABLE_NAME)
	       , SCHEMA_LINK = paste0("http://example.com/schema#", TABLE_SCHEMA)
	       )%>%
	select(subject, TABLE_NAME, SCHEMA_LINK) %>%
	pivot_longer(names_to = 'predicate', values_to = 'object', -subject) %>%
	mutate(predicate = paste0("http://example.com/table#", predicate))

tables_construct  <- rdf()

pmap(list(tables_refined$subject, tables_refined$predicate, tables_refined$object), rdf_add, rdf = tables_construct)

tables_construct

}

schm_construct_rdf_of_columns <- function(.in){

columns <- dbGetQuery(.in, 'select TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS')



columns_refined <- columns %>%
	rowid_to_column("subject") %>%
	mutate(
	       subject = paste0("http://example.com/schema#",TABLE_SCHEMA ,"/table#",TABLE_NAME ,"/column#", COLUMN_NAME)
	       , TABLE_LINK = paste0("http://example.com/schema#", TABLE_SCHEMA,  "/table#", TABLE_NAME)
	       )%>%
	select(subject, COLUMN_NAME, TABLE_LINK) %>%
	pivot_longer(names_to = 'predicate', values_to = 'object', -subject) %>%
	mutate(predicate = paste0("http://example.com/column#", predicate))


columns_construct  <- rdf()

pmap(list(columns_refined$subject, columns_refined$predicate, columns_refined$object), rdf_add, rdf = columns_construct)

columns_construct

}


schm_construct_rdf_of_constraints <- function(.in = conn){

constraints <- dbGetQuery(.in, 'select REFERENCED_TABLE_SCHEMA, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME, CONSTRAINT_NAME, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME from INFORMATION_SCHEMA.KEY_COLUMN_USAGE') 


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
	       
}
