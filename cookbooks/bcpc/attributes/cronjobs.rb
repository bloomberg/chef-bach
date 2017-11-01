default['bcpc']['cronjobs'].tap do |cron|
  cron['clear_tmp']['frequency'] = 604_800 # in seconds (at 1 week)
  cron['clear_tmp']['atime_age'] = 7 # in days
end
