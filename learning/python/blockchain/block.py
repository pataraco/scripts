from time import time


class Block:
    def __init__(self, index, prev_block_hash, proof, transactions, timestamp=None):
        self.index = index
        self.prev_block_hash = prev_block_hash
        self.proof = proof
        self.timestamp = time() if timestamp is None else timestamp
        self.transactions = transactions

    def __repr__(self):
        return (
            f"index: [{self.index}]"
            + f" previous block hash: ({self.prev_block_hash})"
            + f" proof: <{self.proof}>"
            + f" time stamp: {self.timestamp}\n"
            + f"\ttransactions: {self.transactions}"
        )

    def to_dict(self):
        transactions_dicts = [t.__dict__ for t in self.transactions]
        block_dict = dict(
            index=self.index,
            prev_block_hash=self.prev_block_hash,
            proof=self.proof,
            timestamp=self.timestamp,
            transactions=transactions_dicts,
        )
        return block_dict
