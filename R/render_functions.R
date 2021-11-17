## Rendering Functions

### Set of functions to take the data from the sparql system and show as a diagram

### Generate Table Forms
## Connect to SPARQL Server

schm_get_tables <- function(.from_sparql_endpoint) {

d <- SPARQL(
	    url= .from_sparql_endpoint
	    , query="
		PREFIX table:  <http://example.com/table#>
		PREFIX column: <http://example.com/column#>

		SELECT ?column ?table ?column_name ?table_name
		WHERE {
    			?column column:TABLE_LINK ?table  .    
		  	?column column:COLUMN_NAME ?column_name .
  			?table table:TABLE_NAME ?table_name .
		}
	"
)

d[[1]] 

}

### Rendering results

pure_create_table_DOT <- function(.using_table, .from_table_store){

tbl_cols_string <- .from_table_store %>%
	filter(table_name == .using_table) %>%
	mutate(tbl_cells = glue("<tr><td port ='{row_number()}'>{column_name}</td></tr>")) %>%
	pull(tbl_cells)


tbl_leader_string <- glue('{.using_table} [label=<
	<table border="0" cellborder="1" cellspacing="0">
	<tr><td>----- {.using_table} -----</td></tr>
	')

tbl_follower_string <- '</table>>];'


full_tbl_string <- glue_collapse(c(tbl_leader_string,tbl_cols_string,tbl_follower_string), sep="\n")

full_tbl_string
}


pure_create_ERD_DOT <- function(.using_tables){
graph_leader_string <- 'digraph{
	graph [pad="0.5", nodesep="0.5", ranksep="2"];
	node [shape=plain]
	rankdir=LR;
'

graph_follower_string <- "}"


full_graph_string <- glue_collapse(c(graph_leader_string,.using_tables, graph_follower_string), sep = "\n")

full_graph_string
}
