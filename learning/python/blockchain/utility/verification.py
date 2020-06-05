from utility.hash_utils import hash_block, hash_string
from wallet import Wallet

# global constants

# ASCII escape sequences
BLU = "\x1b[1;34m"  # blue, bold
GRN = "\x1b[1;32m"  # green, bold
NRM = "\x1b[m"  # normal
RED = "\x1b[1;31m"  # red, bold
YLW = "\x1b[1;33m"  # red, bold


class Verification:
    POW_DIGITS = 3  # number of digits for Proof of Work (starting at 0)
    POW_PATTERN = "abc"  # pattern to match for Proof of Work
    # POW string to generate POW hash = transactions+last_block_hash+<proof>
    POW_TEMPLATE = "{t}+{h}+<{p}>"  # Proof of Work string template

    @classmethod
    def generate_guess_string(cls, transactions, last_block_hash, proof):
        txs_dicts = [t.to_ordered_dict() for t in transactions]
        return cls.POW_TEMPLATE.format(
            t=str(txs_dicts), h=str(last_block_hash), p=str(proof)
        )

    @classmethod
    def valid_proof(cls, transactions, last_block_hash, proof):
        guess_str = cls.generate_guess_string(transactions, last_block_hash, proof)
        guess_str_encoded = guess_str.encode()
        guess_hash = hash_string(guess_str_encoded)
        print(f"[debug]: guess_hash ({guess_hash})", end="\r")
        return guess_hash[0 : cls.POW_DIGITS] == cls.POW_PATTERN

    @classmethod
    def validate_blockchain(cls, blockchain):
        """ Validates the blockchain. """
        is_valid = True
        print("Validating the blockchain...")
        for i, block in enumerate(blockchain):
            if i == 0:
                continue
            else:
                prev_block = blockchain[i - 1]
                prev_block_hash = hash_block(prev_block)
                print(f"[debug]: Comparing current block[{i}] ({block})")
                print(f"[debug]:      and previous block[{i-1}] ({prev_block})")
                print(
                    f"[debug]: Current",
                    f"block[prev_block_hash] == prev_block_hash",
                    f"({block.prev_block_hash} == {prev_block_hash})? ",
                    end="",
                )
                if block.prev_block_hash == prev_block_hash:
                    print(f"{GRN}Match!{NRM}")
                else:
                    print(f"{RED}MIS-MATCH{NRM}!")
                    is_valid = False
                print(f"[debug]: Verifying proof of block[{i}] ({block})")
                print(
                    f"[debug]:   Comparing first {cls.POW_DIGITS} digits",
                    f"to match '{cls.POW_PATTERN}' in the hash created from:",
                )
                txs_without_mining_reward = block.transactions[:-1]
                print(
                    f"[debug]:   Transactions ({txs_without_mining_reward})",
                    f"last block hash ({block.prev_block_hash}) and proof",
                    f"({block.proof})",
                )
                if cls.valid_proof(
                    txs_without_mining_reward, block.prev_block_hash, block.proof,
                ):
                    proof_succeeded = True
                else:
                    proof_succeeded = False
                    is_valid = False
                print()
                guess_str = cls.generate_guess_string(
                    txs_without_mining_reward, block.prev_block_hash, block.proof,
                )
                print(f"[debug]: guess_str: ({guess_str})")
                if proof_succeeded:
                    print(f"[debug]:   Proof {GRN}Succeeded{NRM}!")
                else:
                    print(f"[debug]:   Proof {RED}FAILED{NRM}!")
        return is_valid

    @staticmethod
    def valid_tx(transaction, get_balance, check_funds=True):
        """ Verify a transaction by checking if the sender has sufficient funds.
        Arguments:
            :transaction: The transaction that should be verified.
            :get_balance: The function used to the the sender's balance.
        """
        if check_funds:
            sender_bal = get_balance(transaction.sender)
            return sender_bal >= transaction.amount and Wallet.verify_tx(transaction)
        else:
            return Wallet.verify_tx(transaction)

    @classmethod
    def validate_txs(cls, transactions, get_balance):
        """ Verifies all transactions given.
        Arguments:
            :transactions: The transactions that should be verified.
            :get_balance: The function used to the the sender's balance.
        """
        return all([cls.valid_tx(t, get_balance) for t in transactions])
