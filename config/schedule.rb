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

# Send 'after' video reminder on Monday at 4pm (24 hours before due)
every :monday, :at => '4pm' do
  runner "Checkin.send_after_checkin_email"
end

every :tuesday, :at => '3:25pm' do
  runner "Checkin.email_startups_not_completed_checkin_yet"
end

# Identify active/inactive teams after the 'after' checkin
every :tuesday, :at => '4:30pm' do 
  runner "Startup.identify_active_teams"
end

# Identify active/inactive teams after the 'before' checkin
every :wednesday, :at => '4:30pm' do 
  runner "Startup.identify_active_teams"
end 

# Send 'before' video reminder on Wednesday at 4am (12 hours before due)
every :wednesday, :at => '4am' do
  runner "Checkin.send_before_checkin_email"
end
  
# Activate all teams who have completed join requirements (it's now for the prev week's class because a new class is started at 1pm)
every :wednesday, :at => '2pm' do
  runner "WeeklyClass.current_class.previous_class.activate_all_completed_startups"
end

# Send email to all people who didn't join this week to join again next week
every :wednesday, :at => '2:05pm' do
  runner "WeeklyClass.email_incomplete_startups_from_previous_week"
end

every 24.hours, :at => '1am' do
	runner "Stats.calculate_engagement_metrics"
end

# Clear out notification older than a week
# every :sunday, :at => '12pm' do
#   runner "Notification.delete_old_notifications"
# end