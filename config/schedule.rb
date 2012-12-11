# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every 12.hours do
  command "cd ~/Backup && bundle exec backup perform --triggers db_backup"
end

# Send reminder to everyone who has a checkin due within 24 hours
every 1.hour do
  runner "Checkin.send_checkin_email"
end

every 30.minutes do
  runner "Response.expire_all_uncompleted_responses"
end

# every 24.hours, :at => '11:25pm' do
#   runner "Checkin.email_startups_not_completed_checkin_yet"
# end

# Identify active/inactive teams after the default checkin
every 24.hours, :at => '12:30am' do 
  runner "Startup.identify_active_teams"
end

# Clean out old session ids from ab tests
every :sunday, :at => '9pm' do
  runner "AbTest.clean_old_session_ids"
end

every 24.hours, :at => '1am' do
	runner "Stats.calculate_engagement_metrics"
end