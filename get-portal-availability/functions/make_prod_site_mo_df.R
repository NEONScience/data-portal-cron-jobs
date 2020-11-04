make_prod_site_mo_df <- function(products){
  p2 <- products[which(products$productStatus=="ACTIVE"), ]
  psm <- data.frame(productID = NA, 
                    productName = NA, 
                    team = NA, 
                    sites = NA, 
                    siteCodes = NA, 
                    months = NA)
  for(i in 1:nrow(p2)){
    pID <- p2$productCode[i]
    pN <- p2$productName[i]
    t <- p2$productScienceTeamAbbr[i]
    s <- length(unlist(p2$siteCodes[[i]]$siteCode))
    sC <- paste(unlist(p2$siteCodes[[i]]$siteCode), collapse = ",")
    if(is.null(sC)) sC <- ""
    m <- length(unlist(p2$siteCodes[[i]]$availableMonths))
    psm <- rbind(psm, data.frame(productID = pID, productName = pN, team = t, sites = s, siteCodes = sC, months = m))
  }
  psm <- psm[-1,]
  return(psm)
}