#!/bin/bash

cd $SANDBOX_BINARY

# Download tarballs based on list
while read url; do echo $url; wget $url; done < binaries

# Extract tarballs
for f in *.gz; do tar xzf $f; done

# Prepare MySQL binaries
for b in $(find . -mindepth 1 -maxdepth 1 -type d -name mysql-\*); do v=$(echo $b|cut -d'-' -f2); mv -f $b ./$v; done

# Prepare Percona Server binaries
for b in $(find . -mindepth 1 -maxdepth 1 -type d -name Percona-Server-\*); do v=$(echo $b|cut -d'-' -f3); mv -f $b "./${v}0"; done

# Remove tarballs
find . -mindepth 1 -maxdepth 1 -type f -name \*.tar.gz -exec rm -rf {} \;

# Create sandboxes
for v in $(find . -mindepth 1 -maxdepth 1 -type d); do 
	NODE_OPTIONS="--my_clause=log_slave_updates=1 --my_clause=sync_binlog=0 --my_clause=innodb_flush_log_at_trx_commit=2" \
	make_replication_sandbox --sandbox_base_port=$(basename $v|sed 's/\.//g') $(basename $v) \
		--how_many_slaves=1 -- --no_confirm;
done

# Run sysbench scripts
for b in $(find $SANDBOX_HOME/ -mindepth 1 -maxdepth 1 -type d -name rsandbox_\*); do ( run-sysbench $(basename $b|cut -d'_' -f2,3,4|sed 's/_//g') & ) ; done