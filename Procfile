web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
runner: env QUEUE=* bundle exec rake resque:work
scheduler: bundle exec rake resque:scheduler
cron: bundle exec whenever -w