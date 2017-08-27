#!/bin/bash

ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0755 /usr/local/pyxbackup/pyxbackup

cd /home/vagrant/xb

# Download tarballs based on list
while read url; do echo $url; wget $url; done < binaries

# Extract tarballs
for f in *.gz; do tar xzf $f; done

# Prepare xtrabackup binaries
for b in $(find . -mindepth 1 -maxdepth 1 -type d -name percona-xtrabackup-\*); do v=$(echo $b|cut -d'-' -f3); mv -f $b ./$v; done

# Remove tarballs
find . -mindepth 1 -maxdepth 1 -type f -name \*.tar.gz -exec rm -rf {} \;