import sys, traceback, os, errno, signal
import time, calendar, shutil, re, pwd
from datetime import datetime, timedelta
from struct import unpack

xb_binlogs_list = [['b1', 1485564648], ['b2', 1485764648], ['b3', 1485903391], ['b4', 1486103391]]
xb_opt_retention_binlogs = 3

def date(unixtime, format = '%m/%d/%Y %H:%M:%S'):
    d = datetime.fromtimestamp(unixtime)
    return d.strftime(format)

def _out(tag, *msgs):
    s = ''

    if not msgs:
        return

    for msg in msgs:
        s += str(msg)

    out = "[%s] %s: %s" % (date(time.time()), tag, s)

    print out

def _say(*msgs):
    _out('INFO', *msgs)

def _purge_binlogs_to(old_binlog):
    if xb_binlogs_list is None: return

    if xb_opt_retention_binlogs is None:
        for l in xb_binlogs_list:
            if l < old_binlog:
                _say("Deleting old binary log %s" % l)
                os.remove(os.path.join(xb_stor_binlogs, l))
    else:
        x = int(time.time())-(xb_opt_retention_binlogs*24*60*60)
        prev = None
        prev_ts = None
        _say("Binlog retention start %s" % str(datetime.fromtimestamp(x).strftime('%Y-%m-%d %H:%M:%S')))
        _say("Current timestamp %s" % str(datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')))
        for l in xb_binlogs_list:
            ts = l[1]
            ts_out = str(datetime.fromtimestamp(l[1]).strftime('%Y-%m-%d %H:%M:%S'))
            _say("%s created at %s" % (l[0], ts_out))

            if prev is not None: 
                if ts < x:
                    _say("Pruning %s" % prev)
                    prev = l[0]
                # Current binlog creation ts is later than start of retention period
                # We keep from this binlog and keep the previous one as well
                else: 
                    _say("%s matches binary log retention period, stopping" % l[0])
                    break
            elif prev is None:
                prev = l[0] 

_purge_binlogs_to(None)

