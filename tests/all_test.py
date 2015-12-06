#!/usr/bin/python

import sys
import pyxbackup as pxb
import pytest

def test__parse_port_param():
    assert(pxb._parse_port_param('27017,27019')) == True
    assert(pxb.xb_opt_remote_nc_port_min) == 27017
    assert(pxb.xb_opt_remote_nc_port_max) == 27019
    assert(pxb._parse_port_param('27017, 27019')) == True
    assert(pxb._parse_port_param('abcde, 27019')) == False
    assert(pxb._parse_port_param('abcde, ')) == False
    assert(pxb._parse_port_param('9999, ')) == False
    assert(pxb._parse_port_param('9999 ')) == False
    assert(pxb._parse_port_param('9999')) == True
    assert(pxb.xb_opt_remote_nc_port_min) == 9999
    assert(pxb.xb_opt_remote_nc_port_max) == 9999