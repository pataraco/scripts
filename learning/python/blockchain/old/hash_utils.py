import hashlib
import json


def hash_string_256(string):
    return hashlib.sha256(string).hexdigest()


def generate_hash(block):
    """ Generates hash of a block in the blockchain.
    Arguments:
        <block> The block that shoud be hashed.
    """
    return hash_string_256(json.dumps(block, sort_keys=True).encode())
    # return hashlib.sha256(json.dumps(block, sort_keys=True).encode()).hexdigest()
    # return '-'.join([str(block[key]) for key in block])
    # return hash(str(block))
