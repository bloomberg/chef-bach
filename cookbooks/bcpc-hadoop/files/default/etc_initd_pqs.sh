#!/bin/sh -e

###############################################
##   WARNING - THIS FILE IS MANAGED BY CHEF  ##
## DO NOT MODIFY BY HAND, OR YOU'LL BE SORRY ##
###############################################

# wrap phoenix query server py script with an init script

### BEGIN INIT INFO
# Provides: phoenix-queryserver
# Required-Start $network $named
# Default-Start: 2 3 4 5
# Default-Stop 0 1 6
# Short-Description: Manages phoenix query server
# Description: Manages phoenix query server
### END INIT INFO

. /lib/lsb/init-functions

PQS_PY_INIT="/usr/bin/phoenix-queryserver"
PID_FILE="/var/run/hbase/phoenix-root-server.pid"
DAEMON="python"
NAME="Phoenix Query Server"
PQS_USER="phoenixrs"

case "$1" in
start)
  log_action_begin_msg "Starting phoenix-queryserver"
  sudo -u phoenixrs $PQS_PY_INIT start
  log_end_msg $?
  ;;
  
stop)
  log_action_begin_msg "Stopping phoenix-queryserver"
  $PQS_PY_INIT stop
  log_end_msg $?
  ;;

restart)
  if [ -f "$PID_FILE" ]; then
    $0 stop
    sleep 1
  fi
  $0 start
  ;;   

status)
  status_of_proc -p "$PID_FILE" "$DAEMON" "$NAME"
  exit $?
  ;;

*)
  echo "Usage: /etc/init.d/pqs {start|stop|restart|status}"
  exit 1
esac

exit 0
