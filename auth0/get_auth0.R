packages <- c('tidyverse', 'lubridate', 'stringr', 'httr', 'jsonlite')
invisible(lapply(packages, library, character.only = TRUE, quietly = TRUE))

dir <- '~/Box/NEON_Data_Portal/UserAnalytics/data-portal-cron-jobs'
outputDir <- file.path(dir, 'auth0')

source(file.path(dir, 'api_tokens.R'))

api_query_url <- "https://data-neonscience.auth0.com/oauth/token/"
headers <- add_headers("Content-Type" = "application/json")
body <- paste('{"client_id":"', api_client_id , '","client_secret":"', api_client_secret, '","audience":"', api_audience ,'","grant_type":"client_credentials"}',sep = "")

response <-POST(api_query_url, config = headers, body=body)

response_content <- content(response)
access_token <- response_content$access_toke

get_Auth0_data <- function(endpoint, token){
  request <- httr::GET(paste0("https://data-neonscience.auth0.com/api/v2/", endpoint), 
                       add_headers(Authorization = paste("Bearer", token, sep = " "), search_engine="v3"))
  content <- jsonlite::fromJSON(httr::content(request, as = "text"))
  return(as_tibble(content))
}

# This needs to be written as a *.rds file because of nested columns
auth0_users <- do.call(rbind, lapply(as.list(seq(1,15, by=1)), function(i) {
  Sys.sleep(5)
  df_out <- get_Auth0_data(endpoint = paste0('users?per_page=100&page=', i), token = access_token) 
  
  if(nrow(df_out) != 1) {
    df_out <- df_out %>%
      rowwise() %>%
      mutate(last_password_reset = ifelse("last_password_reset" %in% names(.), last_password_reset, NA),
             last_login = ifelse("last_login" %in% names(.), last_login, NA),
             last_ip = ifelse("last_ip" %in% names(.), last_ip, NA),
             logins_count = ifelse("logins_count" %in% names(.), logins_count, NA)) %>%
      dplyr::select(email, email_verified, given_name,family_name, created_at,updated_at,user_id, name, nickname, last_password_reset, last_login,last_ip, logins_count)
    return(df_out)
  } else {
    return(tibble(email = NA, email_verified = NA, given_name = NA,family_name = NA, created_at = NA,updated_at = NA,user_id = NA, name = NA, nickname = NA, last_password_reset = NA, last_login = NA,last_ip = NA, logins_count = NA))
      }
    }
  ))

previous_users <- list.files(outputDir, full.names = TRUE, pattern = 'auth0_users_report_')

if(!identical(previous_users, character(0))) {
  previous_df <- readr::read_rds(previous_users)
  auth0_users <- bind_rows(auth0_users, previous_df)
  unlink(previous_users)
}

readr::write_rds(auth0_users, path = file.path(outputDir, paste0('auth0_users_report_20191219-', format(Sys.Date(), "%Y%m%d"), '.rds')))

# Get the daily active users
active_users <- tibble(active_users = get_Auth0_data(endpoint = 'stats/active-users', token = access_token)[[1]],
                       date = Sys.Date())

previous_active_users <- list.files(outputDir, full.names = TRUE, pattern = 'auth0_active_users_report_')

if(!identical(previous_active_users, character(0))) {
  previous_df <- readr::read_rds(previous_active_users)
  active_users <- bind_rows(active_users, previous_df)
  unlink(previous_active_users)
}
  
readr::write_rds(active_users, path = file.path(outputDir, paste0('auth0_active_users_report_20191219-', format(Sys.Date(), "%Y%m%d"), '.rds')))






