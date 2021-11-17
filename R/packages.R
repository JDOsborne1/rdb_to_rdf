# Utility Wrapper

strong_library  <- function(...){
	if(!require(...)){
		install.packages(..., repos = 'https://cloud.r-project.org')
	} else {
		library(...)
	}
}

# Structural Packages

##strong_library("targets")

# data processing packages
	
strong_library("dplyr")
strong_library("tidyr")
strong_library("tibble")
strong_library("rdflib")
strong_library("purrr")

# connection packages

strong_library("SPARQL")
strong_library("dbplyr")
strong_library("DBI")
strong_library("odbc")
strong_library("RMariaDB")

# String Processing packages

strong_library("glue")

