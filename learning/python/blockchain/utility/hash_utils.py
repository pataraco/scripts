import hashlib
import json


def hash_string(string):
    return hashlib.sha256(string).hexdigest()


def hash_block(block):
    """ Generates hash of a block in the blockchain.
    Arguments:
        <block> The block that shoud be hashed.
    """
    block_dict = block.__dict__.copy()
    block_dict["transactions"] = [
        t.to_ordered_dict() for t in block_dict["transactions"]
    ]
    return hash_string(json.dumps(block_dict, sort_keys=True).encode())
    # return hash_string_256(json.dumps(block, sort_keys=True).encode())
    # return hashlib.sha256(json.dumps(block, sort_keys=True).encode()).hexdigest()
    # return '-'.join([str(block[key]) for key in block])
    # return hash(str(block))
