# nReduce Rails App

## App Dependencies

### RVM
Here's how to install from scratch:

    curl -L https://get.rvm.io | bash -s stable --ruby
    rvm install ruby-1.9.3-p125-falcon
    rvm use ruby-1.9.3-p125-falcon
    rvm create gemset nreduce-web
    echo "rvm 1.9.3-p125-falcon@nreduce-web" >> .rvmrc
    cd ../nreduce

### Postgres
Standard Postgres install - nothing special required. Just create the database, and then copy database config and edit:

    cp config/database.sample.yml config/database.yml

### Redis
Used as in-memory cache, as well as by Resque (background job queue)

    brew install redis

### Rmagick
Used for image resizing. To install on OS X, first make sure you have the latest version of Xcode (free download from App Store). Uninstall imagemagick if it was installed:

    brew uninstall imagemagick

Then install imagemagick using homebrew with these flags:

    brew install imagemagick --disable-openmp

### Install gems, migrate, start server

    bundle install
    bundle exec rake db:migrate
    bundle exec rails s

## Testing
All tests are currently written in RSpec, and can run continuously during development using guard. To start the test suite:

    bundle exec guard start

## Deployment
Right now it's a manual script deploy. SSH to the server and run ./script/restart to pull from github, merge, bundle install, and restart thins. Uncomment asset deployment command to precompile assets.

### Resque
Background job processor with multiple queues. Admins can see job status at /resque/. Workers are used mostly to send emails, as well as write queued UserAction objects to disk. To start a background worker on all queues run this:

    RAILS_ENV=production PIDFILE=./tmp/pids/resque.pid BACKGROUND=yes QUEUE=* bundle exec rake environment resque:work

### Resque Scheduler
Handles delayed jobs, start only ONE worker, which pushes delayed jobs onto resque job queue when scheduled:

    RAILS_ENV=production PIDFILE=./tmp/pids/resque_scheduler.pid BACKGROUND=yes bundle exec rake environment resque:scheduler

### Whenever
For sending periodic emails to remind everyone to check in (see config/schedule.rb). To write the tasks to the crontab on the server:

    bundle exec whenever -w

### DB Backup
All sample config is in /Backup folder, which you can copy over to home folder of the DB server. You'll need to then install the gems necessary. Here's how to do it:

    cp Backup ~/
    cd ~/Backup
    rvm create gemset backup
    echo 'rvm 1.9.3-p125-falcon@backup' >> .rvmrc
    bundle init
    echo "gem 'backup'" >> Gemfile
    echo "gem 'fog', '~> 1.1.0'" >> Gemfile
    echo "gem 'mail', '~> 2.4.0'" >> Gemfile

Make sure to edit config.rb to add S3 keys and SMTP config. Test backup by running:

    bundle exec backup perform --triggers db_backup

Then add that to the schedule.rb file and update whenever.

To unencrypt the backup database:

    backup decrypt --encryptor openssl --base64 --salt --in <encrypted_file> --out <decrypted_file>

