#!/bin/bash

EMAIL=email@example.com

last_backup_dt=$(ssh mysql@10.200.0.7 \
    '/backups/primary/mysql/xbackup/xbackup -q --meta-item=xb_last_backup meta')
last_backup_dt=$(echo $last_backup_dt|sed 's/[-_]/ /g'\
    |awk '{printf "%04d-%02d-%02d %02d:%02d:%02d", $1, $2, $3, $4, $5, $6}')
last_backup_dt=$(date -d "$last_backup_dt" +%s)

now_dt=$(date +%s)
last_backup_was_n_seconds_ago=$(($now_dt-$last_backup_dt))

if [ $last_backup_was_n_seconds_ago -ge 39600 ]; then
    (
        echo "Subject: MySQL backup from $(hostname) has problems!";
        echo "The last backup was more than 6hrs ago!";
    )  | mail -s "MySQL backup from $(hostname) has problems!" ${EMAIL}
fi