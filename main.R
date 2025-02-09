# Main Process

source(here::here("R/packages.R"))
source(here::here("R/render_functions.R"))
source(here::here("R/rdf_constructor_function.R"))

cG <- config::get

## Connect to SPARQL Server

d <- SPARQL(
	    url="localhost:3030/test_ds"
	    , query="SELECT distinct ?p WHERE { ?s ?p ?o . }"
	    , ns=c(
		   c('constraint','<http://example.com/constraint#>')
		   , c('column','<http://example.com/column#>')
		   , c('table', '<http://example.com/table#>')
		   , c('schema', '<http://example.com/schema#>')
		   ##, c('ex', 'http://example.com/')
	    )
)

print(d$results)

## Connect to MySQL Server


conn  <- dbConnect(
		   MariaDB()
		   , user = cG('sql_username')
		   , password = cG('sql_password')
		   , host = cG('sql_host')
		   , port = cG('sql_port')
)

dbListObjects(conn)

## Obtain predicateship triples from schema

## Insert Triples nto SPARQL set 

### Constraints

constraints_construct <- schm_construct_rdf_of_constraints(.in = conn)

rdf_serialize(constraints_construct, "constraints_test.rdf", format = 'rdfxml')

### Schemas 

schemas_construct <- schm_construct_rdf_of_schemas(.in = conn)

rdf_serialize(schemas_construct, "schemas_test.rdf", format = 'rdfxml')

### Tables

tables_construct <- schm_construct_rdf_of_tables(.in = conn)
rdf_serialize(tables_construct, "tables_test.rdf", format = 'rdfxml')


### columns 
columns_construct <- schm_construct_rdf_of_columns(.in = conn)
rdf_serialize(columns_construct, "columns_test.rdf", format = 'rdfxml')

## Generate GraphViz for ERD

### Generate the tables
table_store <- schm_get_tables(.from_sparql_endpoint = 'localhost:3030/test_ds', .using_schema ='employees')

all_tables <- table_store %>%
	distinct(table_name) %>%
	pull(table_name) %>%
	map(pure_create_table_DOT, .from_table_store = table_store)

### Generate Links
relations_store <- schm_get_relations(.from_sparql_endpoint = 'localhost:3030/test_ds', .using_schema = 'employees')

relations_dot <- pure_create_relation_table_DOT(.using_relations_store = relations_store)

### Display/Write DOT
pure_create_ERD_DOT(
		    .using_tables = all_tables 
		    , .using_relations = relations_dot
		    ) %>%
	 writeLines("test_tbl_2.txt")

