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
