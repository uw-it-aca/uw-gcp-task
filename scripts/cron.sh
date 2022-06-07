#!/bin/bash

# make sure cron is running
/etc/init.d/cron start

# validate args
if [[ $# -ne 2 ]]; then
    echo "usage: ${0##*/} ${1:-cron_schedule} command_plus_args"
    exit 1
fi

CRON_SCHEDULE=${1}
CRON_COMMAND=${2}

(crontab -l 2>/dev/null; echo "${CRON_SCHEDULE} ${CRON_COMMAND}") | crontab -

# do nothing while cron does it's job
tail -f /dev/null
