#!/bin/bash

BACKUP_LEVEL=${1}
BACKUP_SOURCE_PATH=${2}
BACKUP_BUCKET=${3}

BACKUP_DATE=$(date '+%Y-%m-%d')
BACKUP_NAME_BASE=$(hostname).${BACKUP_DATE}.${BACKUP_LEVEL}
BACKUP_LIST_FILE=/tmp/list.${BACKUP_DATE}.${BACKUP_LEVEL}

BUCKET_OBJECT_BASE=gs://${BACKUP_BUCKET}/${BACKUP_NAME_BASE}

INDEX=0
INDEX_TAG=""
MAX_INDEX=10
while true; do
    BACKUP_TAR_OBJECT=${BUCKET_OBJECT_BASE}${INDEX_TAG}.tar
    BACKUP_LIST_OBJECT=${BUCKET_OBJECT_BASE}${INDEX_TAG}.list
    LS=$(gsutil ls ${BACKUP_TAR_OBJECT} 2>&1)
    if [[ $? -ne 0 ]]; then
        break
    fi

    INDEX=$(( $INDEX + 1 ))
    INDEX_TAG="-(${INDEX})"

    if [[$INDEX -eq $MAX_INDEX]]; then
        echo "Backup name conflict limit reached: ${LS}"
        exit 1
    fi
    echo "Backup object name conflict ${BACKUP_TAR_OBJECT}"
done

START_TIME=$(date +%s)

echo "Backing up (level ${BACKUP_LEVEL}) ${BACKUP_SOURCE_PATH} to ${BACKUP_TAR_OBJECT}"

if [[ $BACKUP_LEVEL = "0" ]]; then
    tar -cvvpf - 2>${BACKUP_LIST_FILE} ${BACKUP_SOURCE_PATH} | gsutil cp - ${BACKUP_TAR_OBJECT}
    EXIT_STATUS=$?
else
    echo "Not prepared for level ${BACKUP_LEVEL} backup yet"
    EXIT_STATUS=1
fi

echo "Upload backup inventory ${BACKUP_LIST_OBJECT}"
gsutil cp ${BACKUP_LIST_FILE} ${BACKUP_LIST_OBJECT}
EXIT_STATUS=$?

EXIT_TIME=$(date +%s)
RUN_TIME=$(( EXIT_TIME - START_TIME ))

if [[ -v PUSHGATEWAY ]]; then
    JOB="$1"
    if [[ -z "$RELEASE_ID" ]]; then
        RELEASE_ID=$(echo -n $HOSTNAME | sed -E 's/-cronjob-.+$//')
    fi

    LABELS="job=\"${JOB}\",instance=\"${RELEASE_ID}\""
    PUSHGATEWAY_PATH="metrics/job/${JOB}/instance/${RELEASE_ID}"

    cat <<EOF | curl --silent --show-error --data-binary @- "http://${PUSHGATEWAY}:9091/${PUSHGATEWAY_PATH}"
# HELP backup_job_exit Management command exit code.
# TYPE backup_job_exit gauge
backup_job_exit{${LABELS}} $EXIT_STATUS
# HELP backup_job_finished Time management command last finished.
# TYPE backup_job_finished gauge
backup_job_finished{${LABELS}} $EXIT_TIME
# HELP backup_job_duration Duration of latest management command.
# TYPE backup_job_duration gauge
backup_job_duration{${LABELS}} $RUN_TIME
EOF
fi
