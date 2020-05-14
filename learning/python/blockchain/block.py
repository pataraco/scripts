from collections import OrderedDict
import json
import pickle
import sys
from time import time

import hash_utils

# initialize/define globals
# constants
SAVE_FILE = "blockchain.data"  # for binary format
# SAVE_FILE = "blockchain.txt"  # for text format
MINING_REWARD = 10
POW_DIGITS = 3  # number of digits for Proof of Work (starting at 0)
POW_TEMPLATE = "{t}+{h}+<{p}>"  # Proof of Work string template
# POW string used to generate POW hash  = transactions+last_block_hash+<proof>
POW_PATTERN = "abc"  # pattern to match for Proof of Work
GENESIS_BLOCK = {
    "prev_block_hash": "",
    "index": 0,
    "transactions": [],
    "proof": POW_DIGITS,
}
OWNER = "PAR"
# BOGUS_TX = {"sender": "Someone", "recipient": OWNER, "amount": 100.0}
BOGUS_TX = OrderedDict([("sender", "Someone"), ("recipient", OWNER), ("amount", 100.0)])
BOGUS_BLOCK = {
    "prev_block_hash": "",
    "index": 0,
    "transactions": [BOGUS_TX],
    "proof": POW_DIGITS,
}

# variables
blockchain = [GENESIS_BLOCK]
open_txs = []
participants = {OWNER}


class Block:
    def __init__(self, index, prev_block_hash, proof, transactions, time=time()):

        self.index = index
        self.prev_block_hash = prev_block_hash
        self.proof = proof
        self.timestamp = time
        self.transactions = transactions
