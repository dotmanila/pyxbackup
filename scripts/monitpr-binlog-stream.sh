#!/bin/bash

PIDFILE=/tmp/pyxbackup-binlog-stream.pid
EMAIL=email@example.com
PID=0
ERROR=""

while true; do
    if [ ! -f $PIDFILE ]; then
        ERROR="PID file $PIDFILE does not exist!"
        break
    fi

    PID=$(cat $PIDFILE)
    if [ "$PID" -le "0" ]; then
        ERROR="PID file $PIDFILE has invalid value!"
        break
    fi

    PROC=$(ps ax|grep mysqlbinlog|grep $PID)
    PID_B=$(echo $PROC|awk '{print $1}')
    if [ "$PID" != "$PID_B" ]; then
        ERROR="PID file $PIDFILE value is different from mysqlbinlog process!"
        break
    fi

    DEFUNCT=$(echo $PROC|grep defunct)
    if [ "$?" -eq 0 ]; then
        ERROR="mysqlbinlog process is marked as defunct!"
        break
    fi

    break
done

if [ "$ERROR" != "" ]; then
    (
        echo "Subject: MySQL binlog streaming from $(hostname) has problems!";
        echo "The error returned was: $ERROR";
    )  | mail -s "MySQL binlog streaming from $(hostname) has problems!" ${EMAIL}
fi