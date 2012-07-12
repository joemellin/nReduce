#! /bin/bash

### BEGIN INIT INFO
# Provides:          unicorn
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the unicorn web server
# Description:       starts unicorn
### END INIT INFO

USER=josh
DIR=/var/www/nreduce
NAME=unicorn
CMD="bundle exec unicorn_rails -c $DIR/config/unicorn.rb -E production -D"
DESC="Unicorn app for $USER - nReduce"
PID=$DIR/tmp/pids/unicorn.pid
CD_TO_APP_DIR="cd $DIR"

case "$1" in
  start)
        echo -n "Starting $DESC: "
        if [ `whoami` = root ]; then
          su - $USER -c "$CD_TO_APP_DIR > /dev/null 2>&1 && $CMD"
        else
          $CD_TO_APP_DIR > /dev/null 2>&1 && $CMD
        fi
        echo "$NAME."
        ;;
  stop)
        echo -n "Stopping $DESC: "
        kill -QUIT `cat $PID`
        echo "$NAME."
        ;;
  restart)
        echo -n "Restarting $DESC: "
        kill -USR2 `cat $PID`
        echo "$NAME."
        if [ `whoami` = root ]; then
          su - $USER -c "$CD_TO_APP_DIR > /dev/null 2>&1 && $CMD"
        else
          $CD_TO_APP_DIR > /dev/null 2>&1 && $CMD
        fi
        ;;
  reload)
        echo -n "Reloading $DESC configuration: "
        kill -HUP `cat $PID`
        echo "$NAME."
        ;;
  *)
        echo "Usage: $NAME {start|stop|restart|reload}" >&2
        exit 1
        ;;
esac

exit 0