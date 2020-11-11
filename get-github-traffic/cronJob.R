library(cronR)

# sourceDir <- '/home/NEON/mietkiewicz/cRON/get-github-traffic/'
sourceDir <- '/Users/mietkiewicz/Box/NEON_Data_Portal/UserAnalytics/data-portal-cron-jobs/get-github-traffic/'

# This is the proper code for the daily runs.
cron_add(command = cron_rscript(paste0(sourceDir, 'github_traffic.R')),
         frequency = 'daily', at='23:30', days_of_week = 0, 
         id = 'github-traffic')

# cron_rm('github-traffic')
# cron_clear(ask=FALSE) 
# 
# cron_add(command = cron_rscript(paste0(sourceDir, 'github_traffic.R')),
#          frequency = 'daily', at='20:00', days_of_week = 3,
#          id = 'github-test')
# 
# cron_rm('github-test')
