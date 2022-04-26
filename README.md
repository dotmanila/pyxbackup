pyxbackup
*********

Summary
=======

This backup script is somewhat a rewrite of https://github.com/dotmanila/mootools/blob/master/xbackup.sh.

Features
========

- Can prepare a full + incrementals set with one command
- Keep backups (full and/or incrementals) prepared on source or remote server
- Compression with xbstream+gzip, tar+gzip, xbstream+qpress
- Support for encryption on top of compression via Xtrabackup encryption
- Stream backups directly to remote servers via scp or netcat, can also keep local copies
- Binary log streaming support with mysqlbinlog 5.6+

Dependencies
============

Python 3.x compatible, needs "configparser" and "pymysql" to be installed. Of course xtrabackup is also needed. Tested with Percona MySQL 8 and xtrabackup 8. No guarantee to be backwards compatible to Python 2.7.

Also it requires that the xtrabackup binaries i.e. innobackupex, xtrabackup*, xbstream are found in your PATH environment.



Configuration
=============

A file called ``pyxbackup.cnf`` can store configuration values. By default, the script looks for this file from ``/etc/pyxbackup.cnf`` first, if not found, on the same directory where the script is installed. It can also be specified from a manual location with the ``--config`` CLI option. Some configuration options are exclusive to the command line, they are marked with ``(cli)`` when executing ``pyxbackup.py --help``.

You can also use multiple configuration sections akin to MySQL's popular ``--defaults-group`` option in your ``pyxbackup.cnf``.

Below are some valid options recognized from the configuration file:

    [pyxbackup]
    # MySQL credentials that can be used to the instance
    # being backed up, only user and pass are used at the 
    # time of this writing
    mysql_host = 127.0.0.1
    mysql_user = msandbox
    mysql_pass = msandbox
    mysql_port = 56190
    mysql_sock = /tmp/mysql.sock
    
    # Instructs the script to run prepare on a copy of the backup
    # with redo-only. The script will maintain a copy of every
    # backup inside work_dir and keep applying with redo-only
    # until the next full backup is executed
    apply_log = 1

    # Whether to compress backups
    compress = 1
    # What compression tool, supports gzip and qpress
    compress_with = gzip

    # Send abckup failure notifications to these addresses, separated by comma
    notify_by_email = myemail@example.com
    # Send backup completion notifications to these adresses,
    # separated by comma
    notify_on_success = myemail@example.com

    # Where to stor raw (compressed) backups on the local directory
    # If --remote-push-only is specified, this is still needed but
    # they will not contain the actual backups, only meta information
    # and logs will remain to keep the backup workflow going
    stor_dir = /sbx/msb/msb_5_6_190/bkp/stor
    # When apply-log is enabled, this is where the "prepared-full"
    # backup will be kept and also stage as temp work dir if backups
    # compression is enabled
    work_dir = /sbx/msb/msb_5_6_190/bkp/work

    # When specified, this value will be passed as --defaults-file to
    # innobackupex
    mysql_cnf = /sbx/msb/msb_5_6_190/my.sandbox.cnf

    # When streaming/copying backups to remote site
    # this is the destination. It should have the same structure as
    # stor_dir with full, incr, weekly, monthly folders within
    remote_stor_dir = /sbx/msb/msb_5_6_190/bkp/stor_remote
    # Remote host to stream to
    remote_host = 127.0.0.1
    # Optional SSH options when streaming with rsync
    # "-o PasswordAuthentication=no -q" is already specified by default
    ssh_opts = "-i /home/revin/.ssh/id_rsa"
    # The SSH user to use when streaming to remote
    ssh_user = root

    # When apply_log is enabled, this is how much memory in MB
    # will be used for --use-memory option with innobackupex
    prepare_memory = 128

    # How many sets of full + incrementals to keep in stor
    retention_sets = 2
    # How many archived weekly backups are kept, unused for now
    retention_weeks = 0
    # How many archived monthly backups are kept, unused for now
    retention_months = 0
    # When using binary log streaming, by default, the script will maintain
    # the oldest binary log based on the oldest backup. This can be overridden 
    # by setting a customer retention period for binary logs for special
    # cases
    retention_binlogs = 365

    # Same functions as innobackupex --encrypt --encrypt-key-file options
    # to support for encrypted backups at rest
    encrypt = AES256
    encrypt_key_file = /path/to/backups/key

    # innobackupex has a lot of options not covered by this wrapper
    # therefore to support additional options, you can pass additional
    # parameters to innobackupex using this option. Enclose them in single or 
    # double quotes and specify them as you would when running innobackupex
    # manually. Take into account to not conflict with options like
    # --compress, --encrypt*, --remote* as these are used in extended 
    # fashion by pyxbackup. 
    #
    # Note that anything after the equal sign is included, quotes are not 
    # stripped since innobackupex can have options that will require quotes 
    # i.e. --include=REGEXP
    extra_ibx_options = --slave-info --galera-info

    # When using Percona Server with Changed Page Tracking enabled, the
    # script can also purge the bitmaps automatically provided that it is
    # configured with valid credentials with SUPER privileges
    purge_bitmaps = 1

    # By default, when storing backups to a remote storage, scp/ssh streaming is
    # used. If you want to use netcat, simply specify using this option the 
    # netcat port to open on the remote server. The script will use SSH to connect
    # to the remote server and open the nc port, make sure that the SSH user
    # has the privilege to open the port i.e. try to use unprivileged port 
    # instead.
    #
    # If you have multiple backups running at the same time and storing to the 
    # same server, make sure to assign unique ports to each.
    remote_nc_port=9999

    # When pushing backups to remote Linux servers, you can specify
    # the path to the pyxbackup script on the remote server and 
    # other config/options
    # file if they are not in default locations ($PATH and /etc/pyxbackup.cnf)
    remote_script=/usr/local/bin/pyxbackup --config=/path/to/custom/pyxbackup.cnf

    # configures --parallel switch of xtrabackup
    parallel = 4

    # configures --rebuild-threads switch of xtrabackup (only needed if prepare is used)
    rebuild_threads = 4
Minimum Configuration
=====================

At the very least, you should have the ``stor_dir`` and ``work_dir`` directories created. Inside ``stor_dir``, the folders **full**, **incr**, **weekly** and **monthly** will be created if they do not exist yet. When running the backup, you should specify these options on the command line or via the configuration file above.

If you are streaming files to remote server, you should also have, aside from the 2 directories previously mentioned, the ``remote_stor_dir`` precreated withe the full, incr, weekly and monthly folders created as well.

Quick Install
=============

First, create your local backup folders and install a single dependency:

    mkdir /backups/folder/stor
    mkdir /backups/folder/work
    pip3 install ConfigParser pymysql
    wget https://raw.githubusercontent.com/dotmanila/pyxbackup/master/pyxbackup
    chmod 0755 pyxbackup

Run you first backup!

    ./pyxbackup full

See more `Configuration`_ options above.

Compressed Backups
==================

There are several types of compressed backups when the ``compress`` option is enabled and each can be decompressed manuall if needed in different ways:

tar + gzip (*.tar.gz)
---------------------

This backup is a result when ``compress`` is enabled with combined with ``apply_log`` and ``compress_with=gzip``. Decompressing is fairly straighforward using the tar utility:

    tar xzvf /path/to/backup.tar.gz -C /path/to/destination/folder


Streamed + gzip (*.xbs.gz)
--------------------------

Same as tar+gz but without the ``apply-log`` option, because we can stream the backup directly, we use xbstream format for potential optimizations like ``rsync`` for local copies and ``parallel`` options.

    gzip -cd /path/to/backup.xbs.gz | xbstream -x -C /path/to/destination/folder


Non-Streamed qpress (*.qp)
--------------------------

Similar to tar+gz, but using qpress as compression binary for when ``apply-log`` is enabled.

    qpress -d /path/to/backup.qp /path/to/destination/folder

Streamed qpress (*.xbs.qp)
--------------------------

When ``apply-log`` is not used, and ``compress_with=qpress``, this will be the format. It takes 2 steps to prepare the backup before being used.
    
    cat /path/to/backup.xbs.qp | xbstream -x -C /path/to/destination/folder

    innobackupex --decompress /path/to/destination/folder


Encrypted Backups (*.qp.xbcrypt)
--------------------------------

When ``apply-log`` is enabled with encryption, compression is implicitly set to qpress. To decompress and decrypt, you can use a command like below:

    xbcrypt --decrypt --encrypt-algo=ENCRYPT_ALGO \
        --encrypt-key-file=/path/to/encryption/key \
        --input=/path/to/backup.qp.xbcrypt \
        | qpress -di /path/to/destination/folder


Streamed Encrypted Backups (*.xbs.qp.xbcrypt)
---------------------------------------------

Similar to the previous format, except this is streamed with xbstream i.e. ``apply-log`` is disabled or ``remote_push_only`` is enabled.

    xbcrypt --decrypt --encrypt-algo=ENCRYPT_ALGO \
        --encrypt-key-file=/path/to/encryption/key \
        --input=/path/to/backup.qp.xbcrypt \
        | xbstream -x -C /path/to/destination/folder

    innobackupex --decompress /path/to/destination/folder


Binary Log Streaming
====================

Streaming binary logs can be done with the script via the ``binlog-stream`` command. The advantage of doing it via the script and the same configuration file as your backups is that it can keep track of your backups and automatically prune binary logs. For example, when your oldest full backup was taken 2 weeks ago, then your oldest binary log file on archive will correspond to that backup as well.

Binary log streaming requires that you configure the ``mysql_host``, ``mysql_user``, ``mysql_pass`` options or on the command line. Additionally aside from ``REPLICATION SLAVE`` privilege, you also need ``REPLICATION CLIENT`` as te script uses ``SHOW BINARY LOGS`` command using the MySQL account.

A simple invocation would look like:

    pyxbackup binlog-stream

In some cases, if you are backing up data from a slave but want to stream the binary logs from the master, the script needs to know this is what you want as the master and slave will have a different set of binary logs. For this, you can specify the option ``--binlog-from-master`` or set ``binlog_from_master=1`` on the configuration file.

As mentioned above, binary log streaming relies on the availability of your oldest full backup. If you do not have this, or simply want to override, you can specify the ``--first-binlog`` option with the name of the binary log from the server you want to stream from.

Additionally, if you want a custom retention period i.e. longer than your oldest backup, ``--retention-binlogs`` can help. This is specified in the number of days and can be as far back as you want. This feature relies on the ``timestamp`` header of each binary log when pruning older copies and not on filesystem metadata.

Examples
========

Assuming I have a very minimal ``pyxbackup.cnf`` below:

    [pyxbackup]
    stor_dir = /sbx/msb/msb_5_6_190/bkp/stor
    work_dir = /sbx/msb/msb_5_6_190/bkp/work
    retention_sets = 2

Running a Full Backup
---------------------

Taking a full backup:

    pyxbackup full

Running an Incremental Backup
-----------------------------

Taking an incremental backup:

    pyxbackup incr

Listing Existing Backups
------------------------

Listing existing backups - also will help identify incomplete/failed backups that may be consuming disk space:

    pyxbackup list

Checking Status of Last Backup
------------------------------

Support for Zabbix/Nagios tests for monitoring:

    pyxbackup --status-format=[nagios|zabbix] status

Keeping a Running "prepared-full" Backup
----------------------------------------

When enabled, a special folder inside the ``work_dir`` will be maintained. This is prefixed with **P_** and the timestamp will correspond to the last full backup that has been taken. When the full backup is taken, a ``--redo-only`` will be applied to it, any succeeding incrementals will be prepared to the same. When in need of a recent snapshot, this special folder can be a quick source.

    pyxbackup --apply-log full

One Touch Prepare of Specific Backup
------------------------------------

For example, I have these 2 backup sets with 2 incrementals each:

    [revin@forge ~]$ pyxbackup list
    # Full backup: 2014_10_15-11_32_32, incrementals: ['2014_10_15-11_34_17', '2014_10_15-11_32_41']
    # Full backup: 2014_10_15-11_32_04, incrementals: ['2014_10_15-11_32_23', '2014_10_15-11_32_14']

If I want to prepare the backup ``2014_10_15-11_32_41`` and make it ready for use, I will use the following command:

    pyxbackup --restore-backup=2014_10_15-11_32_41 \
        --restore-dir=/sbx/msb/msb_5_6_190/bkp/tmp restore-set

After this command, I will have a folder ``/sbx/msb/msb_5_6_190/bkp/tmp/P_2014_10_15-11_32_41`` ready for use i.e. to provision a slave or staging server.

