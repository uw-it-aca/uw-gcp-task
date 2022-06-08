#!/bin/bash

# validate args
if [[ $# -ne 1 ]]; then
    echo "usage: ${0##*/} crontab_file"
    exit 1
fi

# make sure cron is running
/etc/init.d/cron start

# append given crontab
( crontab -l 2>/dev/null;
  cat ${1}
) | crontab -

# let cron do it's job
tail -f /dev/null
