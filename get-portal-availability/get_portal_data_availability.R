# portal_data_availability.R

library(devtools)
library(tidyverse)
library(reshape2)
library(jsonlite)
library(RMySQL)

outdir <- '~/Box/NEON_Data_Portal/UserAnalytics/data-portal-cron-jobs/get-portal-availability'

list_functions <- list.files(file.path(outdir, 'functions'), pattern="*.R$", 
                           full.names=TRUE, ignore.case=TRUE)
invisible(sapply(list_functions, source, .GlobalEnv))

# Pull current product and site data from the API
products <- jsonlite::fromJSON(txt = "http://data.neonscience.org/api/v0/products")$data
saveRDS(products, file.path(outdir, "construction_progress/products.rds"))

sites <- jsonlite::fromJSON("http://data.neonscience.org/api/v0/sites")$data
saveRDS(sites, file.path(outdir, "construction_progress/sites.rds"))

# Load static data ---------------------------
sites_d1_d20 <- readRDS(file.path(outdir, "construction_progress/sites_d1_d20.rds"))

# Product-site combination statistics -----------

# special case data products
dp_ecbundle <- "DP4.00200.001"
dp_eddycov <- c("DP1.00010.001", "DP1.00007.001", "DP1.00034.001","DP1.00035.001","DP1.00036.001", "DP1.00037","DP1.00099.001",
                "DP1.00100.001", "DP2.00008.001","DP2.00009.001","DP2.00024.001","DP3.00008.001","DP3.00009.001",
                "DP3.00010.001","DP4.00002.001","DP4.00007.001","DP4.00067.001",
                "DP4.00137.001","DP4.00201.001")
dp_external_by_type <- list(phenocam = c("DP1.00033.001","DP1.20002.001","DP1.00042.001"), 
                            aeronet = "DP1.00043.001",
                            mgrast = c("DP1.10107.001","DP1.20279.001","DP1.20281.001",
                                       "DP1.10108.001","DP1.20280.001","DP1.20282.001",
                                       "NEON.DP1.20126","DP1.20221.001"),
                            bold = c("DP1.10020.001","DP1.10038.001","DP1.10076.001","DP1.20105.001"))
dp_external_all <- c(dp_external_by_type$phenocam, dp_external_by_type$aeronet,
                     dp_external_by_type$mgrast, dp_external_by_type$bold)

# Create a reference site factored vector (all sites that exist) 
s <- character()
for(i in 1:length(sites_d1_d20)){
  s <- c(s, sites_d1_d20[[i]])
}
s2 <- data.frame(site = factor(s, levels = s))

# assign eddy covariance bundle characteristics to the respective data products
products$productStatus[which(products$productCode %in% dp_eddycov)] <- "ACTIVE"

# remove any DP0 products that sneak in
if(length(grep("DP0.", products$productCode) > 0)){products <- products[-grep("DP0.", products$productCode), ]}

# make a matrix with product x site x month totals
psm <- make_prod_site_mo_df(products)

# assign eddy covariance bundle characteristics to the respective data products
psm$sites[which(psm$productID %in% dp_eddycov)] <- psm$sites[which(psm$productID == dp_ecbundle)]
psm$siteCodes[which(psm$productID %in% dp_eddycov)] <- psm$siteCodes[which(psm$productID == dp_ecbundle)]
psm$months[which(psm$productID %in% dp_eddycov)] <- psm$months[which(psm$productID == dp_ecbundle)]

# remove the eddy covariance bundle product
psm_clean <- psm[-which(psm$productID == dp_ecbundle), ]
psm_clean <- psm_clean[which(psm_clean$sites > 0), ]

# Create another data frame from the prior, parse the site code strings and create a new row for each product site combo.
psm_long <- data.frame(productID = NA, team = NA, site = NA)
psm_clean_2 <- psm_clean[which(psm_clean$siteCodes!=""),]
for(i in 1:nrow(psm_clean_2)){
  st <- strsplit(psm_clean_2[i, ]$siteCodes, ",")
  for(j in 1:length(st[[1]])){
    d <- c(psm_clean_2$productID[i], psm_clean_2$team[i], st[[1]][j])
    psm_long <- rbind(psm_long, d)
  }
}
psm_long <- psm_long[-1, ]

psm_long$loc <- rep("web",nrow(psm_long))
psm_long$loc[which(psm_long$productID %in% dp_external_all)] <- "ext"
psm_long$site <- factor(x=psm_long$site, levels = s2$site)
psm_long <- psm_long[order(psm_long$productID, psm_long$site), ]

construction_dir <- file.path(outdir, 'construction_progress/monthly_figures')
previous_month <- lubridate::as_date(Sys.time() - months(1)) %>%
  stringr::str_split('-') %>%
  unlist() %>%
  paste(., collapse = '') %>%
  stringr::str_sub(., end = 6) 
stringi::stri_sub(previous_month, 5, 2) <- '-'
previous_month_dir <- file.path(construction_dir, previous_month)

var_dir <- list(previous_month_dir)
lapply(var_dir, function(x) if(!dir.exists(x)) dir.create(x, showWarnings = FALSE))

write_rds(psm_long, file.path(previous_month_dir, paste0('product_availability_', previous_month,'.RDS')))
