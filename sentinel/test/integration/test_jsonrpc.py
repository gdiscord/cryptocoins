import pytest
import sys
import os
import re
os.environ['SENTINEL_ENV'] = 'test'
os.environ['SENTINEL_CONFIG'] = os.path.normpath(os.path.join(os.path.dirname(__file__), '../test_sentinel.conf'))
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'lib'))
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))
import config

from ariond import ArionDaemon
from arion_config import ArionConfig


def test_ariond():
    config_text = ArionConfig.slurp_config_file(config.arion_conf)
    network = 'mainnet'
    is_testnet = False
    genesis_hash = u'0000082da923a04678394f873852c7f08b777af30224b6e23296f586370e80ae'
    for line in config_text.split("\n"):
        if line.startswith('testnet=1'):
            network = 'testnet'
            is_testnet = True
            genesis_hash = u'00000742d220d3335b2700881011d1a77471336592fab40141a11bcd04b2fcb5'

    creds = ArionConfig.get_rpc_creds(config_text, network)
    ariond = ArionDaemon(**creds)
    assert ariond.rpc_command is not None

    assert hasattr(ariond, 'rpc_connection')

    # Arion testnet block 0 hash == 00000bafbc94add76cb75e2ec92894837288a481e5c005f6563d91623bf8bc2c
    # test commands without arguments
    info = ariond.rpc_command('getinfo')
    info_keys = [
        'blocks',
        'connections',
        'difficulty',
        'errors',
        'protocolversion',
        'proxy',
        'testnet',
        'timeoffset',
        'version',
    ]
    for key in info_keys:
        assert key in info
    assert info['testnet'] is is_testnet

    # test commands with args
    assert ariond.rpc_command('getblockhash', 0) == genesis_hash
