#!/bin/bash

PORT=$1

sysbench --db-driver=mysql --mysql-user=msandbox --mysql-password=msandbox \
	--mysql-db=test --mysql-host=127.0.0.1 --mysql-port=$PORT --tables=2 \
	--table-size=100000 --auto-inc=off --threads=1 \
	--time=0 --rate=2 --rand-type=pareto oltp_read_write cleanup

sysbench --db-driver=mysql --mysql-user=msandbox --mysql-password=msandbox \
	--mysql-db=test --mysql-host=127.0.0.1 --mysql-port=$PORT --tables=2 \
	--table-size=100000 --auto-inc=off --threads=1 \
	--time=0 --rate=2 --rand-type=pareto oltp_read_write prepare

sysbench --db-driver=mysql --mysql-user=msandbox --mysql-password=msandbox \
	--mysql-db=test --mysql-host=127.0.0.1 --mysql-port=$PORT --tables=2 \
	--table-size=100000 --auto-inc=off --threads=1 \
	--time=0 --rate=2 --rand-type=pareto oltp_read_write run