# nReduce Rails App

## App Dependencies

### RVM
* rvm install ruby-1.9.3-p125-falcon
* rvm use ruby-1.9.3-p125-falcon
* rvm create gemset nreduce-web

### MySQL
Standard MySQL install - nothing special required.

### Redis
Used as in-memory cache, as well as by Resque
* brew install redis

### Resque
Background job processor with multiple queues. Admins can see job status at /resque/. Workers are used mostly to send emails, as well as write queued UserAction objects to disk. To start a background worker on all queues run this:
* RAILS_ENV=production PIDFILE=./tmp/pids/resque.pid BACKGROUND=yes QUEUE=* bundle exec rake environment resque:work

### Whenever
For sending periodic emails - write to crontab on the server:
* bundle exec whenever -w

### Rmagick
Used for image resizing. To install on OS X:
* Make sure you have the latest version of Xcode (free download from App Store)
* brew install imagemagick --disable-openmp


# Testing
All tests are currently written in RSpec, and can run continuously during development using guard. To start the test suite:
* bundle exec guard start
