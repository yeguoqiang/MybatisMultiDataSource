#!/usr/bin/env bash

FILE_PATH=
SERVER_NAME=template-project
readonly APP_HOME=${FILE_PATH:-$(dirname $(cd `dirname $0`; pwd))}

echo "APP_HOME : $APP_HOME"

readonly CONFIG_HOME="$APP_HOME/config/"
readonly LIB_HOME="$APP_HOME/lib"

readonly PID_FILE="$APP_HOME/application.pid"
readonly APP_MAIN_CLASS="template-project.jar"
readonly LOG_CONFIG="$CONFIG_HOME/logback-spring.xml"

readonly JAVA_RUN="-Dlogs.home=$APP_HOME -Dlogging.config=$LOG_CONFIG -Dspring.config.location=file:$CONFIG_HOME -Dspring.pid.file=$PID_FILE -Dspring.pid.fail-on-write-error=true"
readonly JAVA_OPTS="-server -Xms2048m -Xmx2048m -XX:PermSize=256M -XX:MaxPermSize=512M $JAVA_RUN"

readonly JAVA="java"

PID=0


if [ ! -x "$APP_HOME" ]
then
  mkdir $APP_HOME
fi
chmod +x -R "$JAVA_HOME/bin/"

functions="/etc/functions.sh"
if test -f $functions ; then
  . $functions
else
  success()
  {
    echo " SUCCESS! $@"
  }
  failure()
  {
    echo " ERROR! $@"
  }
  warning()
  {
    echo "WARNING! $@"
  }
fi

function install(){

  if [[ ! -n $FILE_PATH ]];then
    sed -i "s#FILE_PATH=#FILE_PATH=$APP_HOME#" $APP_HOME/$0

    if [[ -e /usr/sbin/$SERVER_NAME || -L /usr/sbin/$SERVER_NAME ]];then

      rm -rf /usr/sbin/$SERVER_NAME && ln -s $APP_HOME/$0 /usr/sbin/$SERVER_NAME

    fi
  fi
}

function checkpid() {
   PID=$(ps -ef | grep $APP_MAIN_CLASS | grep -v 'grep' | awk '{print int($2)}')
    if [[ -n "$PID" ]]
    then
      return 0
    else
      return 1
    fi
}

function start() {
   checkpid
   if [[ $? -eq 0 ]]
   then
      warning "[$APP_MAIN_CLASS]: already started! (PID=$PID)"
   else
      echo -n "[$APP_MAIN_CLASS]: Starting ..."
      JAVA_CMD="nohup $JAVA $JAVA_OPTS -jar $LIB_HOME/$APP_MAIN_CLASS > /dev/null 2>&1 &"
      echo "Exec cmmand : $JAVA_CMD"
      sh -c "$JAVA_CMD"
      sleep 3
      checkpid
      if [[ $? -eq 0 ]]
      then
         success "(PID=$PID) "
      else
         failure " "
      fi
   fi
}

function stop() {
   checkpid
   if [[ $? -eq 0 ]];
   then
      echo -n "[$APP_MAIN_CLASS]: Shutting down ...(PID=$PID) "
      kill -9 $PID
      if [[ $? -eq 0 ]];
      then
	     echo 0 > $PID_FILE
         success " "
      else
         failure " "
      fi
   else
      warning "[$APP_MAIN_CLASS]: is not running ..."
   fi
}

function status() {
   checkpid
   if [[ $? -eq 0 ]]
   then
      success "[$APP_MAIN_CLASS]: is running! (PID=$PID)"
      return 0
   else
      failure "[$APP_MAIN_CLASS]: is not running"
      return 1
   fi
}

function info() {
   echo "System Information:"
   echo 
   echo "****************************"
   echo `head -n 1 /etc/issue`
   echo `uname -a`
   echo
   echo "JAVA_HOME=$JAVA_HOME"
   echo 
   echo "JAVA Environment Information:"
   echo `$JAVA -version`
   echo
   echo "APP_HOME=$APP_HOME"
   echo "APP_MAIN_CLASS=$APP_MAIN_CLASS"
   echo 
   echo "****************************"
}

case "$1" in
   'start')
      start
      ;;
   'stop')
     stop
     ;;
   'restart')
     stop
     start
     ;;
   'status')
     status
     ;;
   'info')
     info
     ;;
   'install')
     install
     ;;
    *)
     echo "Usage: $0 {help|start|stop|restart|status|info|install}"
     ;;
esac
exit 0
