from uuid import uuid4
import json
import pickle
import sys

from block import Block
from hash_utils import hash_block
from transaction import Transaction
from verification import Verification

# initialize/define globals
# global constants
# SAVE_FILE = "blockchain.data"  # for binary format
SAVE_FILE = "blockchain.txt"  # for text format
MINING_OWNER = "MINING"
MINING_REWARD = 10
POW_DIGITS = 3  # number of digits for Proof of Work (starting at 0)
POW_TEMPLATE = "{t}+{h}+<{p}>"  # Proof of Work string template
# POW string used to generate POW hash  = transactions+last_block_hash+<proof>
POW_PATTERN = "abc"  # pattern to match for Proof of Work
GENESIS_BLOCK = Block(0, "", POW_DIGITS, [], 0)
OWNER = "PAR"

# for corrupting the chain
BOGUS_TX = Transaction("Someone", str(uuid4()), 100.0)
BOGUS_BLOCK = Block(0, "", POW_DIGITS, [BOGUS_TX], 0)

# ASCII escape sequences
BLU = "\x1b[1;34m"  # blue, bold
D2E = "\x1b[0K"  # delete to EOL
GRN = "\x1b[1;32m"  # green, bold
NRM = "\x1b[m"  # normal
RED = "\x1b[1;31m"  # red, bold
YLW = "\x1b[1;33m"  # red, bold

# gloabal variables


class Blockchain:
    def __init__(self, hosting_node_id):
        # initialize empty blockchain list
        self.__chain = []
        # unprocessed transactions
        self.__open_txs = []
        self.__participants = {MINING_OWNER, hosting_node_id}
        self.load_data()
        self.hosting_node = hosting_node_id

    def corrupt_chain(self):
        if len(self.__chain) > 1:
            self.__chain[1] = BOGUS_BLOCK
        else:
            print("Not enough blocks to corrupt the blockchain")

    def get_chain(self):
        return self.__chain[:]

    def get_open_txs(self):
        return self.__open_txs[:]

    def get_participants(self):
        return self.__participants.copy()

    def load_data(self):
        """ Loads blockchain and open transactions data from a file. """

        # loading data from a "text" file (begin)
        try:
            with open(SAVE_FILE, mode="r") as f:
                blockchain_dicts = json.loads(f.readline())  # list of dicts
                for block_dict in blockchain_dicts:
                    transactions = [
                        Transaction(t["sender"], t["recipient"], t["amount"])
                        for t in block_dict["transactions"]
                    ]
                    block = Block(
                        block_dict["index"],
                        block_dict["prev_block_hash"],
                        block_dict["proof"],
                        transactions,
                        block_dict["timestamp"],
                    )
                    self.__chain.append(block)
                print("[debug]: loaded the blockchain:")
                print(f"[debug]: {self.__chain}")
                open_txs_dicts = json.loads(f.readline())  # list of dicts
                self.__open_txs = [
                    Transaction(t["sender"], t["recipient"], t["amount"])
                    for t in open_txs_dicts
                ]
                print("[debug]: loaded the open transactions:")
                print(f"[debug]: {self.__open_txs}")
        except (IOError, IndexError) as e:
            print(f"[debug]: IOError|IndexError: {e}")
            print(f"IOError|IndexError: trying to read file: {SAVE_FILE}")
            print(f"[debug]: Using genesis block: {GENESIS_BLOCK}")
            self.__chain = [GENESIS_BLOCK]
        except Exception as e:
            print(f"[debug]: Exception (Catch All): {e}")
            print(f"[debug]: Error [{e.__class__.__name__}] ({e.__class__})")
            sys.exit(f"exit: error: {e}: not able to load data")
        # loading data from a "text" file (end)

        # # loading data from a "data" file (begin)
        # try:
        #     with open(SAVE_FILE, mode="rb") as f:
        #         file_content = f.read()
        #         if file_content:
        #             data = pickle.loads(file_content)
        #             self.__chain = data.get("blockchain")
        #             if self.__chain:
        #                 print("[debug]: loaded the blockchain:")
        #                 print(f"[debug]: {self.__chain}")
        #             self.__open_txs = data.get("open_txs")
        #             if self.__open_txs:
        #                 print("[debug]: loaded the open transactions:")
        #                 print(f"[debug]: {self.__open_txs}")
        # except (IOError, IndexError) as e:
        #     print(f"[debug]: IOError/IndexError: {e}")
        #     print(f"IOError/IndexError: trying to read file: {SAVE_FILE}")
        #     print(f"[debug]: Using genesis block: {GENESIS_BLOCK}")
        # except Exception as e:
        #     print(f"[debug]: Exception (Catch All): {e}")
        #     print(f"[debug]: Error [{e.__class__.__name__}] ({e.__class__})")
        #     sys.exit(f"exit: error: {e}: not able to load data")
        # # loading data from a "data" file (end)

        # update/create/load the participants list
        for block in self.__chain:
            for transaction in block.transactions:
                self.__participants.add(transaction.sender)
                self.__participants.add(transaction.recipient)
        for transaction in self.__open_txs:
            self.__participants.add(transaction.sender)
            self.__participants.add(transaction.recipient)

    def save_data(self):
        """ Saves blockchain and open transactions date to a file. """

        # saving data to a "text" file (begin)
        try:
            with open(SAVE_FILE, mode="w") as f:
                # convert transactions to dicts and then blocks to dicts
                blockchain_dicts = [
                    b.__dict__
                    for b in [
                        Block(
                            bce.index,
                            bce.prev_block_hash,
                            bce.proof,
                            [t.__dict__ for t in bce.transactions],
                            bce.timestamp,
                        )
                        for bce in self.__chain
                    ]
                ]
                f.write(json.dumps(blockchain_dicts))
                f.write("\n")
                open_txs_dicts = [t.__dict__ for t in self.__open_txs]  # list of dicts
                f.write(json.dumps(open_txs_dicts))
        except IOError as e:
            print(f"[debug]: IOError: {e}")
            print(f"IOError: trying to save file: {SAVE_FILE}")
        except Exception as e:
            print(f"[debug]: Exception (Catch All): {e}")
            print(f"[debug]: Error [{e.__class__.__name__}] ({e.__class__})")
            sys.exit(f"exit: error: {e}: not able to save data")
        # saving data to a "text" file (end)

        # # saving data to a "data" file (begin)
        # try:
        #     with open(SAVE_FILE, mode="wb") as f:
        #         data = {"blockchain": self.__chain, "open_txs": self.__open_txs}
        #         f.write(pickle.dumps(data))
        # except IOError as e:
        #     print(f"[debug]: IOError: {e}")
        #     print(f"IOError: trying to save file: {SAVE_FILE}")
        # except Exception as e:
        #     print(f"[debug]: Exception (Catch All): {e}")
        #     print(f"[debug]: Error [{e.__class__.__name__}] ({e.__class__})")
        #     sys.exit(f"exit: error: {e}: not able to save data")
        # else:
        #     print(f"[debug]: successfully to saved data to file: {SAVE_FILE}")
        # finally:
        #     print(f"[debug]: here's the data that was saved")
        #     print(f"[debug]: {self.__chain}")
        #     print(f"[debug]: {self.__open_txs}")
        # # saving data to a "data" file (end)

    def proof_of_work(self, transactions, last_block_hash):
        proof = 0
        while not Verification.valid_proof(transactions, last_block_hash, proof):
            proof += 1
        print()
        print(
            f"[debug]: Proof of Work: found the proof ({proof}) that generated a",
            f"hash with the first {POW_DIGITS} digits matching the pattern",
            f"'{POW_PATTERN}'",
        )
        guess_str = Verification.generate_guess_string(
            transactions, last_block_hash, proof
        )
        print(f"[debug]: guess_str: ({guess_str})")
        return proof

    def get_balance(self, participant):
        """ Gets and returns a participants balance. """
        deductions = [
            t.amount
            for block in self.__chain
            for t in block.transactions
            if t.sender == participant
        ]
        additions = [
            t.amount
            for block in self.__chain
            for t in block.transactions
            if t.recipient == participant
        ]
        open_deductions = [t.amount for t in self.__open_txs if t.sender == participant]
        open_additions = [
            t.amount for t in self.__open_txs if t.recipient == participant
        ]
        print(
            f"[debug]: participant: {participant},",
            f"deductions: {RED}{deductions}{NRM} (open: {BLU}{open_deductions}{NRM}),",
            f"additions: {GRN}{additions}{NRM} (open: {BLU}{open_additions}{NRM})",
        )
        return (
            sum(additions)
            + sum(open_additions)
            - sum(deductions)
            - sum(open_deductions)
        )

    def get_last_blockchain_val(self):
        """ Returns the last element of the blockchain list. """
        if len(self.__chain) < 1:
            return None
        return self.__chain[-1]

    def add_tx(self, recipient, sender, amount=1.0):
        """ Adds a transaction to the blockchain
            and current transaction amount to the blockchain list.

            Parameters:

            <sender> The sender of the coins.
            <recipient> The recipient of the coins.
            <amount> The amount of coins transferred (default: 1.0).
        """
        tx = Transaction(sender, recipient, amount)
        if Verification.valid_tx(tx, self.get_balance):
            self.__open_txs.append(tx)
            self.__participants.add(sender)
            self.__participants.add(recipient)
            self.save_data()
            return True
        return False

    def mine_block(self):
        """ Adds a block of current transactions to the blockchain. """
        # reward the miner
        reward_tx = Transaction(MINING_OWNER, self.hosting_node, MINING_REWARD)
        # make a copy in order to preserve open_txs
        new_txs = self.__open_txs[:]
        new_txs.append(reward_tx)
        # add the current transactions
        last_block = self.__chain[-1]
        last_block_hash = hash_block(last_block)
        proof = self.proof_of_work(self.__open_txs, last_block_hash)
        block = Block(len(self.__chain), last_block_hash, proof, new_txs)
        self.__chain.append(block)
        self.__open_txs = []
        self.save_data()
