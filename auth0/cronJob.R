library(cronR)

# sourceDir <- '/home/NEON/mietkiewicz/cRON/auth0/'
sourceDir <- '/Users/mietkiewicz/Box/NEON_Data_Portal/UserAnalytics/data-portal-cron-jobs/auth0/'

# Use this for the test
# cron_add(cron_rscript(paste0(sourceDir, 'get_auth0.R')), 
#          frequency = 'daily', at = '10:40',
#          id = 'auth0-get-daily-stats-test')
# cron_rm('auth0-get-daily-stats')

# Use this for the run
cron_add(cron_rscript(paste0(sourceDir, 'get_auth0.R')), 
         frequency = 'daily', at = '23:30',
         id = 'auth0-get-daily-stats')

# cron_clear(ask=FALSE) 

