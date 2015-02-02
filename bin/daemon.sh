#!/bin/bash

SCRIPT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
PID_FILE="${SCRIPT_PATH}/daemon.pid"
PERL_PROG="/usr/bin/perl"
PROGRAM="${PERL_PROG} -I\"${SCRIPT_PATH}/../lib/\" ${SCRIPT_PATH}/daemon.pl"

usage() {
    echo "Use commands: {start|stop|restart|status}" >&2
}

if [[ -z "${1}" ]]; then
    usage
    exit 1
fi

# Get the PID from PIDFILE if we don't have one yet.
get_pid() {
    if [[ -e ${PID_FILE} ]]; then
        PID=$(cat ${PID_FILE});
    fi
}

start() {
    get_pid
    if [[ -z "${PID}" ]]; then
        echo "Starting daemon."
        ${PROGRAM} & echo $! > ${PID_FILE}
        status
    else
        status
    fi
}
status() {
    get_pid
    if [[ -z "${PID}" ]]; then
        echo "Daemon is not running (missing PID)."
    elif [[ -e /proc/${PID}/exe && "`realpath /proc/${PID}/exe`" == "`realpath ${PERL_PROG}`" ]]; then
        echo "Daemon is running (PID = ${PID})."
    else
        echo "Daemon is not running (incorrect PID = ${PID})."
        > ${PID_FILE}
    fi
}
stop() {
    get_pid
    if [[ -e /proc/${PID}/exe && "`realpath /proc/${PID}/exe`" == "`realpath ${PERL_PROG}`" ]]; then
        echo "Stopping daemon."
        kill $1 ${PID}
        > ${PID_FILE}
        echo "Daemon is stooped."
    else
        status
    fi
}


case "$1" in
    start)
        start;
    ;;
    restart)
        stop;
        
        sleep 1;
        start;
    ;;
    stop)
        stop
    ;;
    status)
        status
    ;;
    *)
        usage
        exit 4
    ;;
esac
exit 0 
