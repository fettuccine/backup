#!/bin/bash

CUR_PATH=`dirname $0`

. "${CUR_PATH}/backup.func.sh"
CONF_PATH="${CUR_PATH}/backup.conf.sh"

load_and_validate_conf ${CONF_PATH}
backup ${WORKING_DIR} ${BACKUP_DIR}


