# bundle exec unicorn_rails -c config/unicorn.rb -E production -D

rails_env = ENV['RAILS_ENV'] || 'production'

# 16 workers and 1 master
worker_processes (rails_env == 'production' ? 4 : 1)

working_directory = rails_env == 'production' ? '/var/www/nreduce' : '/Users/josh/Projects/nreduce'

# Load rails+github.git into the master before forking workers
# for super-fast worker spawn times
preload_app true

# Restart any workers that haven't responded in 30 seconds
timeout 30

# Can't use unix socket with lighttpd so for now listen on port
listen "127.0.0.1:8985"

# Listen on a Unix data socket
#listen working_directory + '/tmp/sockets/unicorn.sock', :backlog => 2048

pid working_directory + '/tmp/pids/unicorn.pid'

# Set the path of the log files inside the log folder
stderr_path working_directory + '/log/unicorn.stderr.log'
stdout_path working_directory + '/log/unicorn.stdout.log'

##
# REE

# http://www.rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end

before_fork do |server, worker|
  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  old_pid = working_directory + '/tmp/pids/unicorn.pid.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end