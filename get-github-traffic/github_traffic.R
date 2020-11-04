# 08 - GitHub Traffic -----------------------------------------------------

library(tidyverse)
library(lubridate)
library(httr)
library(jsonlite)

dir <- '~/Box/NEON_Data_Portal/UserAnalytics/data-portal-cron-jobs'
outputDir <- file.path(dir, 'get-github-traffic')

source(file.path(dir, 'api_tokens.R'))

github_traffic_list <- list.files(outputDir, pattern = 'github-traffic-', full.names = TRUE)

current_date <- lubridate::as_date(Sys.time()) %>%
  stringr::str_split('-') %>%
  unlist() %>%
  paste(., collapse = '')

last_date_collected <- last(basename(github_traffic_list)) %>%
  stringr::str_split('\\.|-') %>%
  lapply(`[`, 5) %>%
  unlist() %>%
  lubridate::as_date(.)

# start with dates from the past two weeks to make sure there are no gaps
timestamp <- as.character(rep(lubridate::as_date(Sys.time()),15)-0:14) %>%
  # .[. > last_date_collected] %>%
  tibble::enframe(name = NULL, value = 'date')

gitList <- c("NEON-utilities","NEON-geolocation",
             "NEON-stream-morphology","NEON-stream-discharge",
             "NEON-Nitrogen-Transformations","NEON-dissolved-gas",
             "NEON-reaeration", "eddy4R", "NEON-IS-data-processing", 'portal-core-components')

historical_clones_views <- read_csv(github_traffic_list[grepl('clones-views', github_traffic_list)])
historical_referrals <- read_csv(github_traffic_list[grepl('referrals', github_traffic_list)])

clones <- do.call(rbind, lapply(as.list(gitList), function(i) {
  
  clone_json <- GET(paste("https://api.github.com/repos/NEONScience/", i,
                          "/traffic/clones", sep=""),
                    accept="application/vnd.github.v3+json",
                    authenticate("NateMietk", GITHUB_TOKEN)) 
  clone_json <- fromJSON(content(clone_json, as="text"), flatten=T)$clones
  
  if(identical(clone_json, list())) {
    clones_out <- timestamp %>%
      mutate(package = i,
             totalClones = 0,
             uniqueClones = 0)
  } else {
    clones_out <- clone_json %>%
      mutate(package = i) %>%
      dplyr::select(date = timestamp, package, totalClones = count,
                    uniqueClones = uniques)
  }
  return(clones_out)
} ))

views <- do.call(rbind, lapply(as.list(gitList), function(i) {
  
  views_json <- GET(paste("https://api.github.com/repos/NEONScience/", i,
                          "/traffic/views", sep=""),
                    accept="application/vnd.github.v3+json",
                    authenticate("NateMietk", GITHUB_TOKEN)) 
  views_json <- fromJSON(content(views_json, as="text"), flatten=T)$views
  
  if(identical(views_json, list())) {
    views_out <- timestamp %>%
      mutate(package = i,
             totalViews = 0,
             uniqueViews = 0)
  } else {
    views_out <- views_json %>%
      mutate(package = i) %>%
      dplyr::select(date = timestamp, package, totalViews = count,
                    uniqueViews = uniques)
  }
  return(views_out)
} ))

refs <- do.call(rbind, lapply(as.list(gitList), function(i) {
  
  refs_json <- GET(paste("https://api.github.com/repos/NEONScience/", i,
                         "/traffic/popular/referrers", sep=""),
                   accept="application/vnd.github.v3+json",
                   authenticate("NateMietk", GITHUB_TOKEN)) 
  refs_json <- fromJSON(content(refs_json, as="text"), flatten=T)
  
  if(identical(refs_json, list())) {
    refs_out <- tibble(
      package = i,
      referrer = NA_character_,
      totalRefViews = 0,
      uniqueRefViews = 0)
  } else {
    refs_out <- refs_json %>%
      mutate(package = i) %>%
      dplyr::select(package, referrer, totalRefViews = count,
                    uniqueRefViews = uniques)
  }
  return(refs_out)
} )) 

# append new page views to the count and unique lists
historical_clones_views <- views %>%
  left_join(., clones, by = c('date', 'package')) %>%
  mutate(date = as_date(date)) %>%
  bind_rows(., historical_clones_views) %>%
  distinct(date, package, .keep_all = TRUE) %>%
  arrange(desc(date))  %>% 
  mutate_if(is.numeric , replace_na, replace = 0)

historical_referrals <- refs %>%
  bind_rows(., historical_referrals) %>%
  group_by(package, referrer) %>% 
  summarize(totalRefViews = sum(totalRefViews), 
            uniqueRefViews= sum(uniqueRefViews)) 

# write out updated records
write_csv(historical_clones_views, file.path(outputDir, paste0("github-traffic-clones-views-201609-", current_date, '.csv')))
write_csv(historical_referrals, file.path(outputDir, paste0("github-traffic-referrals-201609-", current_date, '.csv')))

unlink(github_traffic_list) 

