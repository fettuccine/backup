# backup.sh
Backup script.

# How to use
Specify 2 variable in backup.conf.sh (WORKING_DIR, BACKUP_DIR)  

Example.  

    WORKING_DIR="/folder/to/back/up"  
    BACKUP_DIR="/back/up/folder"  

After setting backup.conf.sh invoke script    

 > ./backup.sh

# Tip
Cron backup.sh to backup periodically.  
Only the modified files and folders will be backup-ed.

