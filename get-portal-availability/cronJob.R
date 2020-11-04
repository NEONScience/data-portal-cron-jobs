library(cronR)

# sourceDir <- '/home/NEON/mietkiewicz/cRON/auth0/'
sourceDir <- '/Users/mietkiewicz/Box/NEON_Data_Portal/UserAnalytics/data-portal-cron-jobs/get-portal-availability'

# Use this for the test
# cron_add(cron_rscript(paste0(sourceDir, 'get_portal_data_availability.R')), 
# cron_add(cron_rscript(file.path(sourceDir, 'get_portal_data_availability.R')), 
#          at = '15:20',
#          id = 'temper')
# 
# cron_rm('temper')

# Use this for the run
cron_add(cron_rscript(file.path(sourceDir, 'get_portal_data_availability.R')),
         frequency = 'monthly', at = '00:01', 
         days_of_month = 'first', days_of_week = '*',
         id = 'get-portal-data-availability')

# cron_clear(ask=FALSE) 