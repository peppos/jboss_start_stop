#! /bin/sh

# Provide start and stop Jboss AS

JBOSS_HOME=/appl/jboss
JBOSS_USER=applmgr
JBOSS_GROUP=applmgr
JBOSS_CONSOLE_LOG=/appl/jboss/standalone/log/server.log
STARTUP_WAIT=60
SHUTDOWN_WAIT=60

JBOSS_BIN=$JBOSS_HOME/bin/standalone.sh
test -x $JBOSS_BIN || exit 5

. /etc/rc.status

rc_reset

case "$1" in
    start)
         PID=`ps -edaf |grep java| grep Standalone | grep -v grep | awk '{print $2}'`
        if [ -n "$PID" ]; then
                echo "Jboss AS Runnig"
        else

        echo "Starting Jboss AS 7.1.0 "
        UID_ENT="$(/usr/bin/getent passwd $JBOSS_USER)"
        GID_ENT="$(/usr/bin/getent group $JBOSS_GROUP)"

        if test -z "$JBOSS_USER" -o -z "$UID_ENT"
        then
            echo
            echo "User $JBOSS_USER does not exist."
            echo "Please check jboss config before starting this service."
            rc_failed
        elif test -z "$JBOSS_GROUP" -o -z "$GID_ENT"
                then
                echo
                echo "Group $JBOSS_GROUP does not exist."
                echo "Please check jboss config before starting this service."
                rc_failed
        else
                if [ $USER == $JBOSS_USER ]; then
                        $JBOSS_BIN 2>&1 > $JBOSS_CONSOLE_LOG &
                        count=0
                        launched=false

                        until [ $count -gt $STARTUP_WAIT ]
                        do
                            grep 'JBoss AS.*started in' $JBOSS_CONSOLE_LOG > /dev/null
                            if [ $? -eq 0 ] ; then
                              launched=true
                                break
                            fi
                            sleep 1
                            let count=$count+1;
                        done

                else
                        echo "Current user not valid! Only $JBOSS_USER can start jboss"
                        rc_failed
                fi
        fi
        fi
        rc_status -v
        ;;
    stop)
        count=0;
        kpid=`ps -edaf |grep java| grep Standalone | grep -v grep | awk '{print $2}'`

        if [ -n "$kpid" ]; then
                echo "Shutting down Jboss AS "
                if [ $USER == $JBOSS_USER ]; then

                        kill -15 $kpid
                        until [ `ps --pid $kpid 2> /dev/null | grep -c $kpid 2> /dev/null` -eq '0' ]
                        do
                                sleep 1
                                let count=$count+1;
                        done

                        if [ "$count" -gt "$SHUTDOWN_WAIT" ]; then
                                kill -9 $kpid
                        fi
                else
                        echo "Current user not valid! Only $JBOSS_USER can stop jboss"
                        rc_failed
                fi
        else
                echo "Jboss AS not running"
        fi

        rc_status -v
        ;;
    restart)
        $0 stop
        $0 start

        rc_status
        ;;
    status)
        echo "Checking for service Jboss AS "
        PID=`ps -edaf |grep java| grep Standalone | grep -v grep | awk '{print $2}'`
        if [ -n "$PID" ]; then
                echo "Jboss AS Runnig"
                rc_status -v
                exit 0
        else
                echo "Jboss AS not running"
                rc_failed
        fi
        rc_status -v
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 1
        ;;
esac
rc_exit
