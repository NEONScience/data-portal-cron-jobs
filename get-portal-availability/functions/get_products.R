get_products <- function(){
  pr <- jsonlite::fromJSON(txt = "http://data.neonscience.org/api/v0/products")
  pr <- pr[["data"]]
  return(pr)
}