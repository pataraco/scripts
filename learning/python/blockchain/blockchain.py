from uuid import uuid4
import json
import requests
import sys

# import pickle  # used for data file types

from block import Block
from utility.hash_utils import hash_block
from transaction import Transaction
from utility.verification import Verification
from wallet import Wallet

# TODO: convert save data back to binary

# initialize/define globals
# global constants
MINING_OWNER = "MINING"
MINING_REWARD = 10
POW_DIGITS = 3  # number of digits for Proof of Work (starting at 0)
POW_TEMPLATE = "{t}+{h}+<{p}>"  # Proof of Work string template
# POW string used to generate POW hash  = transactions+last_block_hash+<proof>
POW_PATTERN = "abc"  # pattern to match for Proof of Work
GENESIS_BLOCK = Block(0, "", POW_DIGITS, [], 0)
OWNER = "PAR"

# for corrupting the chain
BOGUS_TX = Transaction("Someone", str(uuid4()), None, 100.0)
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
    # __SAVE_FILE = "blockchain.data"  # for binary format
    __SAVE_FILE = "blockchain-{}.txt"  # for text format (with port)

    def __init__(self, hosting_node_id, hosting_node_port):
        # initialize empty blockchain list
        self.__chain = []
        # unprocessed transactions
        self.__open_txs = []
        self.__participants = {MINING_OWNER}
        self.hosting_node = hosting_node_id
        self.hosting_port = hosting_node_port
        self.__peer_nodes = set()
        self.load_data()

    # add chain attribute getter method
    @property
    def chain(self):
        """ Defines a getter for the chain attribute. """
        return self.__chain[:]

    # add chain attribute setter method
    @chain.setter
    def chain(self, val):
        """ Defines a setter for the chain attribute. """
        self.__chain = val

    def corrupt_chain(self):
        """ Corrupts the blockchain for testing purposes. """
        if len(self.__chain) > 1:
            self.__chain[1] = BOGUS_BLOCK
        else:
            print("Not enough blocks to corrupt the blockchain")

    def get_chain(self):
        """ Returns the blockchain. """
        return self.__chain[:]

    def get_open_txs(self):
        """ Returns a copy of the open transactions list. """
        return self.__open_txs[:]

    def get_participants(self):
        """ Returns this list of participants. """
        return self.__participants.copy()

    def load_data(self):
        """ Loads blockchain and open transactions data from a file. """

        # loading data from a "text" file (begin)
        try:
            with open(self.__SAVE_FILE.format(self.hosting_port), mode="r") as f:
                blockchain_dicts = json.loads(f.readline())  # list of dicts
                for block_dict in blockchain_dicts:
                    transactions = [
                        Transaction(
                            t["sender"], t["recipient"], t["signature"], t["amount"]
                        )
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
                    Transaction(
                        t["sender"], t["recipient"], t["signature"], t["amount"]
                    )
                    for t in open_txs_dicts
                ]
                print("[debug]: loaded the open transactions:")
                print(f"[debug]: {self.__open_txs}")
                peer_nodes = json.loads(f.readline())
                self.__peer_nodes = set(peer_nodes)
                print("[debug]: loaded the peer nodes")
                print(f"[debug]: {self.__peer_nodes}")
        except (IOError, IndexError) as e:
            print(f"[debug]: IOError|IndexError: {e}")
            print(
                f"IOError|IndexError: trying to load blockchain data",
                f"by reading file: {self.__SAVE_FILE.format(self.hosting_port)}",
            )
            print(f"[debug]: Using genesis block: {GENESIS_BLOCK}")
            self.__chain = [GENESIS_BLOCK]
        except Exception as e:
            print(f"[debug]: Exception (Catch All): {e}")
            print(f"[debug]: Error [{e.__class__.__name__}] ({e.__class__})")
            sys.exit(f"exit: error: {e}: not able to load blockchain data")
        # loading data from a "text" file (end)

        # # loading data from a "data" file (begin)
        # try:
        #     with open(self.__SAVE_FILE.format(self.hosting_port), mode="rb") as f:
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
        #     print(f"IOError/IndexError: trying to read file: {self.__SAVE_FILE.format(self.hosting_port)}")
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
            with open(self.__SAVE_FILE.format(self.hosting_port), mode="w") as f:
                # convert transactions to dicts and then blocks to dicts
                blockchain_dicts = [b.to_dict() for b in self.__chain]
                # old way before 'to_dict' method
                # blockchain_dicts = [
                #     b.__dict__
                #     for b in [
                #         Block(
                #             bce.index,
                #             bce.prev_block_hash,
                #             bce.proof,
                #             [t.__dict__ for t in bce.transactions],
                #             bce.timestamp,
                #         )
                #         for bce in self.__chain
                #     ]
                # ]
                f.write(json.dumps(blockchain_dicts))
                f.write("\n")
                open_txs_dicts = [t.__dict__ for t in self.__open_txs]  # list of dicts
                f.write(json.dumps(open_txs_dicts))
                f.write("\n")
                f.write(json.dumps(list(self.__peer_nodes)))
        except IOError as e:
            print(f"[debug]: IOError: {e}")
            print(
                f"IOError: trying to save blockchain to file: {self.__SAVE_FILE.format(self.hosting_port)}"
            )
        except Exception as e:
            print(f"[debug]: Exception (Catch All): {e}")
            print(f"[debug]: Error [{e.__class__.__name__}] ({e.__class__})")
            sys.exit(f"exit: error: {e}: not able to save blockchain data")
        # saving data to a "text" file (end)

        # # saving data to a "data" file (begin)
        # try:
        #     with open(self.__SAVE_FILE.format(self.hosting_port), mode="wb") as f:
        #         data = {"blockchain": self.__chain, "open_txs": self.__open_txs}
        #         f.write(pickle.dumps(data))
        # except IOError as e:
        #     print(f"[debug]: IOError: {e}")
        #     print(f"IOError: trying to save blockchain data to file: {self.__SAVE_FILE.format(self.hosting_port)}")
        # except Exception as e:
        #     print(f"[debug]: Exception (Catch All): {e}")
        #     print(f"[debug]: Error [{e.__class__.__name__}] ({e.__class__})")
        #     sys.exit(f"exit: error: {e}: not able to save blockchain data")
        # else:
        #     print(f"[debug]: successfully saved blockchain data to file: {self.__SAVE_FILE.format(self.hosting_port)}")
        # finally:
        #     print(f"[debug]: here's the data that was saved")
        #     print(f"[debug]: {self.__chain}")
        #     print(f"[debug]: {self.__open_txs}")
        # # saving data to a "data" file (end)

    def proof_of_work(self, transactions, last_block_hash):
        """ Generates the proof of work to validate the block. """
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
        if participant is None:
            return None
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

    def add_tx(self, sender, recipient, signature, amount=1.0, is_broadcast=False):
        """ Adds a transaction to the blockchain
            and current transaction amount to the blockchain list.

            Parameters:

            :sender: The sender of the coins.
            :recipient: The recipient of the coins.
            :signature: The signature of the transaction.
            :amount: The amount of coins transferred (default: 1.0).
        """
        if self.hosting_node is None:
            return False
        tx = Transaction(sender, recipient, signature, amount)
        # this verification moved to verification.py
        # if not Wallet.verify_tx(tx):
        #     return False
        if Verification.valid_tx(tx, self.get_balance):
            self.__open_txs.append(tx)
            self.__participants.add(sender)
            self.__participants.add(recipient)
            self.save_data()
            if not is_broadcast:
                for node in self.__peer_nodes:
                    url = f"http://{node}/broadcast-transaction"
                    try:
                        print(f"[debug]: trying to broadcast transactions to: {url}")
                        response = requests.post(
                            url,
                            json={
                                "s": sender,
                                "r": recipient,
                                "sig": signature,
                                "a": amount,
                            },
                        )
                        print(f"[debug]: response status code: {response.status_code}")
                        if response.status_code == 400 or response.status_code == 500:
                            print(
                                "[debug]: broadcast transaction failed (needs resolving)"
                            )
                            return False
                    except requests.exceptions.ConnectionError as e:
                        print(f"[debug]: ConnectionError: {e}")
                        print(f"ConnectionError: trying to connect to node: {node}")
                        continue
                    except Exception as e:
                        print(f"[debug]: Exception (Catch All): {e}")
                        print(
                            f"[debug]: Error [{e.__class__.__name__}] ({e.__class__})"
                        )
                        sys.exit(
                            f"exit: error: {e}: not able to connect to node: {node}"
                        )
                        return True
        return False

    def mine_block(self):
        """ Adds a block of current transactions to the blockchain. """
        if self.hosting_node is None:
            return None
        # reward the miner
        reward_tx = Transaction(MINING_OWNER, self.hosting_node, None, MINING_REWARD)
        # make a copy in order to preserve open_txs
        new_txs = self.__open_txs[:]
        # verify the new transactions before adding the reward transaction
        for tx in new_txs:
            if not Wallet.verify_tx(tx):
                return None
        new_txs.append(reward_tx)
        # add the current transactions
        last_block = self.__chain[-1]
        last_block_hash = hash_block(last_block)
        proof = self.proof_of_work(self.__open_txs, last_block_hash)
        block = Block(len(self.__chain), last_block_hash, proof, new_txs)
        self.__chain.append(block)
        self.__participants.add(self.hosting_node)
        self.__open_txs = []
        self.save_data()
        return block

    def add_peer_node(self, node):
        """ Adds a new node to the peer node set.

        Arguments:
            :node: The node URL/Endpoint that should be added.
        """
        self.__peer_nodes.add(node)
        self.save_data()

    def remove_peer_node(self, node):
        """ Removes a node from the peer node set.

        Arguments:
            :node: The node URL/Endpoint that should be removed.
        """
        self.__peer_nodes.discard(node)
        self.save_data()

    def get_peer_nodes(self):
        """ Returns a list of all peer nodes. """
        return list(self.__peer_nodes)
