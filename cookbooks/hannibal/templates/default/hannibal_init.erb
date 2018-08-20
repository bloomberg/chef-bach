#!/bin/bash

export HANNIBAL_INSTALL_DIR=<%= node[:hannibal][:install_dir] %>
export HANNIBAL_HOME="${HANNIBAL_INSTALL_DIR}/hannibal"
export HANNIBAL_PID_DIR=<%= node[:hannibal][:working_dir] %>

DAEMON_SCRIPT="${HANNIBAL_HOME}/start"
NAME="hannibal"
DESC="Hannibal daemon"
CONF_DIR="${HANNIBAL_HOME}/conf"
PATH=$PATH:$HANNIBAL_HOME:$CONF_DIR
PID_FILE=${HANNIBAL_PID_DIR}/RUNNING_PID

if [ -z "$HANNIBAL_HOME" ]; then
  echo "Hannibal home directory ${HANNIBAL_HOME} does not exist."
  exit 1
fi

if [ -z "$HANNIBAL_PID_DIR" ]; then
  echo "Hannibal pid directory ${HANNIBAL_PID_DIR} does not exist."
  exit 1
fi

hannibal_is_process_alive() {
  local pid="$1"
  ps -fp $pid | grep $pid | grep play.core.server.NettyServer > /dev/null 2>&1
}

hannibal_check_pidfile() {
  local pidfile="$1" # IN
  local pid

  pid=`cat "$pidfile" 2>/dev/null`
  if [ "$pid" = '' ]; then
    # The file probably does not exist or is empty.
    return 1
  fi

  set -- $pid
  pid="$1"

  hannibal_is_process_alive $pid
}

hannibal_stop_pidfile() {
  local pidfile="$1" # IN
  local pid

  pid=`cat "$pidfile" 2>/dev/null`
  if [ "$pid" = '' ]; then
    # The file probably does not exist or is empty. Success
    return 0
  fi

  set -- $pid
  pid="$1"

  # First try the easy way
  if hannibal_process_kill "$pid" 15; then
    return 0
  fi

  # Otherwise try the hard way
  if hannibal_process_kill "$pid" 9; then
    return 0
  fi

  return 1
}

hannibal_process_kill() {
  local pid="$1"    # IN
  local signal="$2" # IN
  local second

  kill -$signal $pid 2>/dev/null

  # Wait a bit to see if the dirty job has really been done
  for second in {1..10}; do
    if hannibal_is_process_alive "$pid"; 
    then
      return 0
    fi
    sleep 1
  done
  return 1
}

hannibal_remove_pidfile() {
  local pidfile="$1"
  if [ -f $pidfile ]; then
    rm -f $pidfile
  fi
}

start() {
  cd ${HANNIBAL_PID_DIR}
  su -s /bin/sh root -c "$DAEMON_SCRIPT" > /var/log/hannibal/service.log 2>&1 &
  sleep 5
}

stop() {
  hannibal_stop_pidfile $PID_FILE
  sleep 5
}

case "$1" in
  start)
    echo -n "Starting $DESC: "
    start
    if hannibal_check_pidfile $PID_FILE ; then
      echo "$NAME."
     else
      echo "ERROR."
     fi
  ;;
  stop)
    echo -n "Stopping $DESC: "
    stop
    if hannibal_check_pidfile $PID_FILE ; then
      echo 'ERROR'
    else
      echo "$NAME."
    fi
  ;;
  restart)
    echo -n "Restarting $DESC: "
    stop
    start
  ;;
  status)
    echo -n "$NAME is "
    if hannibal_check_pidfile $PID_FILE ;  then
      echo "running"
    else
      echo "not running."
      exit 1
    fi
    ;;
  *)
  N=/etc/init.d/$NAME
  # echo "Usage: $N {start|stop|restart|reload|force-reload}" >&2
  echo "Usage: $N {start|stop|restart|status}" >&2
  exit 1
  ;;
esac
exit 0
