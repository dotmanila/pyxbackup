#!/bin/bash

cd ~
wget https://github.com/datacharmer/mysql-sandbox/releases/download/3.2.14/MySQL-Sandbox-3.2.14.tar.gz
tar xzf MySQL-Sandbox-3.2.14.tar.gz
cd MySQL-Sandbox-3.2.14/
perl Makefile.PL PREFIX=/usr
make
sudo make install