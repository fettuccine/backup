function file_exist() {
    local FILE_PATH=$1
    local retval;
    if [ ${#FILE_PATH} -eq 0 ] ; then
        retval=1;
    elif [ -f ${FILE_PATH} ] ; then
        if [ -r ${FILE_PATH} ] ; then
            retval=0;
        else
            retval=2;
        fi
    else
        retval=1;
    fi
    echo $retval;
}

function folder_exist() {
    local FOLDER_PATH=$1
    local retval;
    if [ ${#FOLDER_PATH} -eq 0 ] ; then
        retval=1;
    elif [ -d ${FOLDER_PATH} ] ; then
        if [ -r ${FOLDER_PATH} ] ; then
            retval=0;
        else
            retval=2;
        fi
        retval=0;
    else
        retval=1;
    fi
    echo $retval;
}

function check_operating_system() {
    local retval
    if [ "$(uname)" == "Darwin" ] ; then
        retval="Mac"
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ] ; then
        retval="Linux"
    elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ] ; then
        retval="Windows"
    else
        retval="unknown"
    fi
    echo $retval
}

function clear_variable() {
    unset WORKING_DIR
    unset BACKUP_DIR
}

function fix_variable() {
    if [ "${#WORKING_DIR}" -gt 0 ] ; then
        WORKING_DIR=${WORKING_DIR%/}
    fi
    if [ "${#BACKUP_DIR}" -gt 0 ] ; then
        BACKUP_DIR=${BACKUP_DIR%/}
    fi
}

function check_timestamp() {
    local FILE_PATH=$1
    local retval=0
    if [ $(check_operating_system) == "Mac" ] ; then
        retval=`stat -f %m ${FILE_PATH}`
    elif [ $(check_operating_system) == "Linux" ] ; then
        retval=`stat -c %y ${FILE_PATH}`
    fi
    echo ${retval}
}

function check_filesize() {
    local FILE_PATH=$1
    local retval=-1;
    if [ $(check_operating_system) == "Mac" ] ; then
        retval=`du -sk ${FILE_PATH} | awk '{print $1}'`
    elif [ $(check_operating_system) == "Linux" ] ; then
        retval=`stat -c %s ${FILE_PATH}`
    fi
    echo ${retval}
}

function load_conf_file() {
    clear_variable
    . ${CONF_PATH}
    fix_variable
}

function copy_file() {
    local LOCAL_COPYING_FILE=$1
    local LOCAL_BACKUP_FILE=$2
    if [ "${#LOCAL_COPYING_FILE}" -gt 0 -a "${#LOCAL_BACKUP_FILE}" -gt 0 ] ; then
        nohup cp -f ${LOCAL_COPYING_FILE} ${LOCAL_BACKUP_FILE} >/dev/null 2>&1
        echo "[INFO] copied file, ${LOCAL_COPYING_FILE}"
    else
        echo "[ERROR] internal system error. (inside copy file.)"
        exit;
    fi
}

function copy_folder() {
    local LOCAL_COPYING_FOLDER=$1
    local LOCAL_BACKUP_FOLDER=$2
    if [ "${#LOCAL_COPYING_FOLDER}" -gt 0 -a "${#LOCAL_BACKUP_FOLDER}" -gt 0 ] ; then
        local LOCAL_PARENT_DIRECTORY=${LOCAL_BACKUP_FOLDER%/*}
        nohup cp -r ${LOCAL_COPYING_FOLDER} ${LOCAL_PARENT_DIRECTORY} >/dev/null 2>&1
        echo "[INFO] copied folder, ${LOCAL_COPYING_FOLDER}"
    else
        echo "[ERROR] internal system error.(inside copy folder.)"
        exit;
    fi
}

function check_copying_file() {
    local LOCAL_COPYING_FILE=$1
    local LOCAL_BACKUP_FILE
    if [ `file_exist ${LOCAL_COPYING_FILE}` -eq 0 ] ; then
	LOCAL_BACKUP_FILE="${LOCAL_COPYING_FILE/${WORKING_DIR}/${BACKUP_DIR}}"
	if [ "${#LOCAL_BACKUP_FILE}" -eq 0 ] ; then
	    echo "[WARN] internal system error."
            exit;
	elif [ `file_exist ${LOCAL_BACKUP_FILE}` -eq 1 ] ; then
            copy_file ${LOCAL_COPYING_FILE} ${LOCAL_BACKUP_FILE}
	elif [ `file_exist ${LOCAL_BACKUP_FILE}` -eq 0 ] ; then
            local WORKING_TIMESTAMP=$(check_timestamp ${LOCAL_COPYING_FILE})
            local BACKUP_TIMESTAMP=$(check_timestamp ${LOCAL_BACKUP_FILE})
            local WORKING_FILESIZE=$(check_filesize ${LOCAL_COPYING_FILE})
            local BACKUP_FILESIZE=$(check_filesize ${LOCAL_BACKUP_FILE})
            if [ "${WORKING_TIMESTAMP}" -gt "${BACKUP_TIMESTAMP}" -o "${WORKING_FILESIZE}" -ne "${BACKUP_FILESIZE}" ] ; then
                copy_file ${LOCAL_COPYING_FILE} ${LOCAL_BACKUP_FILE}
            else
                echo "[INFO] up to date, ${LOCAL_COPYING_FILE} "
            fi
        else
            echo "[ERROR] could not copy ${LOCAL_COPYING_FILE}"
	fi
    fi
}

function check_copying_folder() {
    local LOCAL_COPYING_FOLDER=$1
    local LOCAL_BACKUP_FOLDER
    if [ `folder_exist ${LOCAL_COPYING_FOLDER}` -eq 0 ] ; then
        LOCAL_BACKUP_FOLDER="${LOCAL_COPYING_FOLDER/${WORKING_DIR}/${BACKUP_DIR}}"
        if [ "${#LOCAL_BACKUP_FOLDER}" -eq 0 ] ; then
            echo "[WARN] internal system error."
            exit;
        elif [ `folder_exist ${LOCAL_BACKUP_FOLDER}` -eq 1 ] ; then
            copy_folder ${LOCAL_COPYING_FOLDER} ${LOCAL_BACKUP_FOLDER}
        elif [ `folder_exist ${LOCAL_BACKUP_FOLDER}` -eq 0 ] ; then
	    for file_or_directory in ${LOCAL_COPYING_FOLDER}/*
	    do
		if [ -f "$file_or_directory" ] ; then
		    check_copying_file ${file_or_directory}
		elif [ -d "$file_or_directory" ] ; then
		    check_copying_folder ${file_or_directory}
		fi
	    done
        fi
    fi
}

function backup() {
    echo "[INFO] begin sync."
    if [ "${#WORKING_DIR}" -eq 0 -o "${#BACKUP_DIR}" -eq 0 ] ; then
        echo "[ERROR] internal system error."
        exit;
   fi
   check_copying_folder ${WORKING_DIR}
   echo "[INFO] end sync."
}

function load_and_validate_conf() {
    local LOCAL_CONF_PATH=$1
    if [ "${#LOCAL_CONF_PATH}" -eq 0 ] ; then
        echo "[ERROR] internal system error."
        exit;
    fi
    if [ `file_exist "${LOCAL_CONF_PATH}"` -eq 0 ] ; then
        load_conf_file
	if [ `folder_exist $WORKING_DIR` -eq 0 ] ; then
	    echo "[INFO] WORKING_DIR is ${WORKING_DIR}."
	else
	    echo "[WARN] WORKING_DIR do not exist or not readable."
	    exit;
	fi
	if [ `folder_exist $BACKUP_DIR` -eq 0 ] ; then
	    echo "[INFO] BACKUP_DIR is ${BACKUP_DIR}."
	else
	    echo "[WARN] BACKUP_DIR do not exist or not readable."
	    exit;
	fi
    else
	echo "[WARN] can not read config file."
	exit;
    fi
}
