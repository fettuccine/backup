#!/bin/bash

. ./backup.func.sh
CONF_PATH="./backup.conf.sh"

load_and_validate_conf ${CONF_PATH}
backup ${WORKING_DIR} ${BACKUP_DIR}


