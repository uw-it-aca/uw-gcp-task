#!/bin/bash
set -e

gcloud auth activate-service-account --key-file $GCLOUD_AUTH_FILE

# execute passed command
$*
