get_sites <- function(){
  sites <- jsonlite::fromJSON("http://data.neonscience.org/api/v0/sites")
  sites <- sites[['data']]
  return(sites)
}