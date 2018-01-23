#!/bin/bash

export SANDBOX_BINARY=/home/ubuntu/mysql
export SANDBOX_HOME=/home/ubuntu/sandboxes

cd /home/ubuntu/
CPATH=/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ubuntu/.local/bin:/home/ubuntu/bin
PPATH="$CPATH:/usr/local/pyxbackup"
export PATH=$PPATH
pyxbackup -X -q wipeout

for d in /p/bkp/stor /p/bkp/work /p/bkp/r/stor /p/bkp/r/work; do
	rm -rf $d/*
done

for v in $(find /home/ubuntu/xb -mindepth 1 -maxdepth 1 -type d); do
	export PATH=$PPATH:/home/ubuntu/xb/$(basename $v)/bin
	echo $PATH

	for b in $(find $SANDBOX_HOME/ -mindepth 1 -maxdepth 1 -type d -name rsandbox_\*); do 
		sb=$(basename $b|cut -d'_' -f2,3,4)
		p=$(echo $sb|sed 's/_//g')
		
		rm -rf /p/bkp/work/pyxbackup.lock
		while read cmd; do 
			xcmd="pyxbackup --mysql-cnf=$SANDBOX_HOME/rsandbox_${sb}/master/my.sandbox.cnf --mysql-sock=/tmp/mysql_sandbox${p}.sock ${cmd}"
			eval $xcmd
			echo "$? $p $(basename $v) $cmd" 
		done < commands-pyxbackup
	done
done

export PATH=$CPATH
