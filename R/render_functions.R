## Rendering Functions

### Set of functions to take the data from the sparql system and show as a diagram

### Generate Table Forms
## Connect to SPARQL Server

schm_get_tables <- function(.from_sparql_endpoint, .using_schema) {

d <- SPARQL(
	    url= .from_sparql_endpoint
	    , query=glue("
		PREFIX table:  <http://example.com/table#>
		PREFIX column: <http://example.com/column#>
		PREFIX schema: <http://example.com/schema#>
		
		SELECT ?column ?table ?column_name ?table_name
		WHERE {
    			?column column:TABLE_LINK ?table  .    
		  	?column column:COLUMN_NAME ?column_name .
  			?table table:TABLE_NAME ?table_name .
			?table table:SCHEMA_LINK ?schema .
			?schema schema:SCHEMA_NAME '[.using_schema]'
		}
		" 
		, .open = '['
		, .close = ']')
)

d[[1]] 

}

### Generating the links
schm_get_relations <- function(.from_sparql_endpoint, .of_class = 'FOREIGN_KEY', .using_schema) {

d <- SPARQL(
	    url= .from_sparql_endpoint
	    , query = glue("PREFIX table:  <http://example.com/table#>
			   PREFIX column: <http://example.com/column#>
			   PREFIX constraint: <http://example.com/constraint#>
			   PREFIX schema: <http://example.com/schema#>

			   SELECT distinct ?con_col ?con_dest_col ?table_name ?table_dest_name
			   WHERE {
				   ?con constraint:constrained_column ?con_col .
				   ?com constraint:constraining_column ?con_dest_col .
				   ?con constraint:constraint_name ?con_name .
				   ?con constraint:constraint_class constraint:[.of_class] .
				   ?con constraint:constraint_class ?con_class .
				   ?con_col  column:TABLE_LINK ?table .
				   ?table table:SCHEMA_LINK ?schema .
				   ?schema schema:SCHEMA_NAME '[.using_schema]' .
				   ?table table:TABLE_NAME ?table_name .
				   ?con_dest_col column:TABLE_LINK ?table_dest .
				   ?table_dest table:TABLE_NAME ?table_dest_name .
			   }"
			   , .open = '['
			   , .close = ']'
	    )
)

d[[1]] 

}



### Rendering results

pure_create_column_DOT <- function(column_uri, column_name){
	uri_digest <- column_uri %>% 
		as.character() %>%
	       	digest()	
	
	"<tr><td bgcolor='white' port ='h{uri_digest}'>{column_name}</td></tr>" %>%
		glue() %>%
		as.character()
}

pure_create_table_DOT <- function(.using_table, .from_table_store){

	tbl_cols_string <- .from_table_store %>%
		filter(table_name == .using_table) %>%
		mutate(tbl_cells = map2_chr(column, column_name, pure_create_column_DOT)) %>%
		pull(tbl_cells)


	tbl_leader_string <- glue('{.using_table} [label=<
				  <table border="0" cellborder="1" cellspacing="0">
				  <tr><td> {.using_table} </td></tr>
				  ')

	tbl_follower_string <- '</table>>];'


	full_tbl_string <- glue_collapse(c(tbl_leader_string,tbl_cols_string,tbl_follower_string), sep="\n")

	full_tbl_string

}

pure_create_column_reference <- function(table_name, column_uri) {
	uri_digest  <- column_uri %>%
		as.character() %>%
		digest()

	"{table_name}:h{uri_digest}" %>%
		glue() %>%
		as.character()
}


pure_create_relation_table_DOT <- function(.using_relations_store){
	.using_relations_store %>%
		mutate(
		       origin_reference = map2_chr(table_name, con_col, pure_create_column_reference)
		       , destination_reference = map2_chr(table_dest_name, con_dest_col, pure_create_column_reference)
		       , link_string = glue("{origin_reference} -> {destination_reference}")	       
		       	) %>%
		pull(link_string) %>%
		unique() %>%
		glue_collapse(sep = "\n")	

}





pure_create_ERD_DOT <- function(.using_tables, .using_relations = ''){
graph_leader_string <- 'digraph{
	graph [pad="0.5", nodesep="0.5", ranksep="2"];
	node [shape=plain]
	rankdir=LR;
'

graph_follower_string <- "}"

all_graphs_string <- glue_collapse(.using_tables, sep = '\n\n')

full_graph_string <- glue_collapse(
				   c(
				     graph_leader_string
				     , all_graphs_string
				     , .using_relations
				     , graph_follower_string
				   )
				   , sep = "\n"
)

full_graph_string
}
