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

#every 12.hours do
#  command "backup perform --trigger db_backup"
#end

# Send 'after' video reminder on Monday at 4pm (24 hours before due)
every :monday, :at => '4pm' do
  runner "Checkin.send_after_checkin_email"
end

# Send 'before' video reminder on Wednesday at 4am (12 hours before due)
every :wednesday, :at => '4am' do
  runner "Checkin.send_before_checkin_email"
end

# Clear out notification older than a week
# every :sunday, :at => '12pm' do
#   runner "Notification.delete_old_notifications"
# end