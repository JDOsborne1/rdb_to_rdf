# Main Process

source(here::here("R/packages.R"))
source(here::here("R/render_functions.R"))
source(here::here("R/rdf_constructor_function.R"))


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

conn  <- dbConnect(MariaDB(), user = 'root', password = 'example', host =  '0.0.0.0', port = '3306')

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

## Generate GraphViz for relational diagram


table_store <- schm_get_tables(.from_sparql_endpoint = 'localhost:3030/test_ds')

test_table <- pure_create_table_DOT(.using_table='employees', .from_table_store = table_store)

test_table2 <- pure_create_table_DOT(.using_table='dept_emp', .from_table_store = table_store)

pure_create_ERD_DOT(
		    .using_tables = c(test_table, test_table2)
		    ) %>%
	 writeLines("test_tbl_2.txt")
## Generate Links
