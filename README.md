pyxbackup
*********

Summary
=======

This backup script is somewhat a rewrite of https://github.com/dotmanila/mootools/blob/master/xbackup.sh.

Features
========

- Can prepare a full + incrementals set with one command
- Keep backups (full and/or incrementals) prepared on source or remote server
- Compression with xbstream+gzip, tar+gzip
- Stream backups directly to remote servers via SSH+rsync
- Binary log streaming support

Dependencies
============

The script is initially tested only with Python 2.6 on CentOS 6.5 and Python 2.7 on Ubuntu 14.04 - running it on newer versions i.e. 3.x may lead to incompatibility issues. Will appreciate pointers/pull requests on making it compatible with Python 3.x!

Also it requires that the xtrabackup binaries i.e. innobackupex, xtrabackup*, xbstream are found in your PATH environment.

Configuration
=============

A file called ``pyxbackup.cnf`` can store configuration values. By default, the script looks for this file on the same directory where it is installed, it can also be specified from a manual location with the ``--config`` CLI option. Some configuration options are exclusive to the command line, they are marked with ``(cli)`` when executing ``pyxbackup.py --help``.

Below are some valid options recognized from the configuration file: ::

    [pyxbackup]
    # MySQL credentials that can be used to the instance
    # being backed up, only user and pass are used at the 
    # time of this writing
    mysql_host = 127.0.0.1
    mysql_user = msandbox
    mysql_password = msandbox
    mysql_port = 56190
    mysql_socket = /tmp/mysql.sock
    # Instructs the script to run prepare on a copy of the backup
    # with redo-only. The scrip will maintain a copy of every
    # backup inside work_dir and keep applying with redo-only
    # until the next full backup is executed
    apply_log = 1
    # Whether to compress backups
    compress = 1
    # What compression tool, only supports gzip for now
    compress_with = gzip
    # Whether to copy binlogs, unused for now
    copy_binlogs = 0
    # Whether to specify --galera-info to innobackupex, unused
    galera_info = 0
    # Send abckup failure notifications to
    notify_by_email = myemail@example.com
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
    retention_weekly = 0
    # How many archived monthly backups are kept, unused for now
    retention_monthly = 0



Minimum Configuration
=====================

At the very least, you should have the ``stor_dir`` and ``work_dir`` directories created. Inside ``stor_dir``, the folders **full**, **incr**, **weekly** and **monthly** will be created if they do not exist yet. When running the backup, you should specify these options on the command line or via the configuration file above.

If you are streaming files to remote server, you should also have, aside from the 2 directories previously mentioned, the ``remote_stor_dir`` precreated withe the full, incr, weekly and monthly folders created as well.


Examples
========

Assuming I have a very minimal ``pyxbackup.cnf`` below: ::

    [pyxbackup]
    stor_dir = /sbx/msb/msb_5_6_190/bkp/stor
    work_dir = /sbx/msb/msb_5_6_190/bkp/work

Running a Full Backup
---------------------

::

    pyxbackup incr

Running an Incremental Backup
-----------------------------

::

    pyxbackup incr

Listing Existing Backups
------------------------

::

    xbackup list

Checking Status of Last Backup
------------------------------

::

    pyxbackup status

Keeping a Running "prepared-full" Backup
----------------------------------------

When enabled, a special folder inside the ``work_dir`` will be maintained. This is prefixed with **P_** and the timestamp will correspond to the last full backup that has been taken. When the full backup is taken, a ``--redo-only`` will be applied to it, any succeeding incrementals will be prepared to the same. When in need of a recent snapshot, this special folder can be a quick source. ::

    pyxbackup --apply-log full

One Touch Prepare of Specific Backup
------------------------------------

For example, I have these 2 backup sets with 2 incrementals each: ::

    [revin@forge ~]$ pyxbackup list
    # Full backup: 2014_10_15-11_32_32, incrementals: ['2014_10_15-11_34_17', '2014_10_15-11_32_41']
    # Full backup: 2014_10_15-11_32_04, incrementals: ['2014_10_15-11_32_23', '2014_10_15-11_32_14']

If I want to prepare the backup ``2014_10_15-11_32_41`` and make it ready for use, I will use the following command: ::

    pyxbackup --restore-backup=2014_10_15-11_32_41 \
        --restore-dir=/sbx/msb/msb_5_6_190/bkp/tmp restore-set

After this command, I will have a folder ``/sbx/msb/msb_5_6_190/bkp/tmp/P_2014_10_15-11_32_41`` ready for use i.e. to provision a slave or staging server.

