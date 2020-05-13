from collections import OrderedDict
import json
import pickle
import sys

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
# ASCII escape sequences
D2E = "\x1b[0K"  # delete to EOL
GRN = "\x1b[1;32m"  # green, bold
NRM = "\x1b[m"  # normal
RED = "\x1b[1;31m"  # red, bold

# variables
blockchain = [GENESIS_BLOCK]
open_txs = []
participants = {OWNER}


def load_data():
    """ Loads blockchain and open transactions data from a file. """
    global blockchain
    global open_txs
    global participants

    # # loading data from a "text" file (begin)
    # try:
    #     with open(SAVE_FILE, mode="r") as f:
    #         line = f.readline()
    #         if line:
    #             blockchain = json.loads(line)
    #             print("[debug]: loaded the blockchain:")
    #             print(f"[debug]: {blockchain}")
    #         line = f.readline()
    #         if line:
    #             open_txs = json.loads(line)
    #             print("[debug]: loaded the open transactions:")
    #             print(f"[debug]: {open_txs}")
    #     # process block and convert transactions to OrderedDicts
    #     for block in blockchain:
    #         block["transactions"] = [
    #             OrderedDict(
    #                 [
    #                     ("sender", tx["sender"]),
    #                     ("recipient", tx["recipient"]),
    #                     ("amount", tx["amount"]),
    #                 ]
    #             )
    #             for tx in block["transactions"]
    #         ]
    #     open_txs = [
    #         OrderedDict(
    #             [
    #                 ("sender", tx["sender"]),
    #                 ("recipient", tx["recipient"]),
    #                 ("amount", tx["amount"]),
    #             ]
    #         )
    #         for tx in open_txs
    #     ]
    # except (IOError, IndexError) as e:
    #     print(f"[debug]: IOError/IndexError: {e}")
    #     print(f"IOError/IndexError: trying to read file: {SAVE_FILE}")
    #     print(f"[debug]: Using genesis block: {GENESIS_BLOCK}")
    # except Exception as e:
    #     print(f"[debug]: Exception (Catch All): {e}")
    #     print(f"[debug]: Error [{e.__class__.__name__}] ({e.__class__})")
    #     sys.exit(f"exit: error: {e}: not able to load data")
    # # loading data from a "text" file (end)

    # loading data from a "data" file (begin)
    try:
        with open(SAVE_FILE, mode="rb") as f:
            file_content = f.read()
            if file_content:
                data = pickle.loads(file_content)
                blockchain = data.get("blockchain")
                if blockchain:
                    print("[debug]: loaded the blockchain:")
                    print(f"[debug]: {blockchain}")
                open_txs = data.get("open_txs")
                if open_txs:
                    print("[debug]: loaded the open transactions:")
                    print(f"[debug]: {open_txs}")
    except (IOError, IndexError) as e:
        print(f"[debug]: IOError/IndexError: {e}")
        print(f"IOError/IndexError: trying to read file: {SAVE_FILE}")
        print(f"[debug]: Using genesis block: {GENESIS_BLOCK}")
    except Exception as e:
        print(f"[debug]: Exception (Catch All): {e}")
        print(f"[debug]: Error [{e.__class__.__name__}] ({e.__class__})")
        sys.exit(f"exit: error: {e}: not able to load data")
    # loading data from a "data" file (end)

    # update/create/load the participants list
    for block in blockchain:
        for transaction in block["transactions"]:
            participants.add(transaction["sender"])
            participants.add(transaction["recipient"])
    for transaction in open_txs:
        participants.add(transaction["sender"])
        participants.add(transaction["recipient"])


def save_data():
    """ Saves blockchain and open transactions date to a file. """

    # # saving data to a "text" file (begin)
    # try:
    #     with open(SAVE_FILE, mode="w") as f:
    #         f.write(json.dumps(blockchain))
    #         f.write("\n")
    #         f.write(json.dumps(open_txs))
    # except IOError as e:
    #     print(f"[debug]: IOError: {e}")
    #     print(f"IOError: trying to save file: {SAVE_FILE}")
    # except Exception as e:
    #     print(f"[debug]: Exception (Catch All): {e}")
    #     print(f"[debug]: Error [{e.__class__.__name__}] ({e.__class__})")
    #     sys.exit(f"exit: error: {e}: not able to save data")
    # # saving data to a "text" file (end)

    # saving data to a "data" file (begin)
    try:
        with open(SAVE_FILE, mode="wb") as f:
            data = {"blockchain": blockchain, "open_txs": open_txs}
            f.write(pickle.dumps(data))
    except IOError as e:
        print(f"[debug]: IOError: {e}")
        print(f"IOError: trying to save file: {SAVE_FILE}")
    except Exception as e:
        print(f"[debug]: Exception (Catch All): {e}")
        print(f"[debug]: Error [{e.__class__.__name__}] ({e.__class__})")
        sys.exit(f"exit: error: {e}: not able to save data")
    else:
        print(f"[debug]: successfully to saved data to file: {SAVE_FILE}")
    finally:
        print(f"[debug]: here's the data that was saved")
        print(f"[debug]: {blockchain}")
        print(f"[debug]: {open_txs}")
    # saving data to a "data" file (end)


def get_last_blockchain_val():
    """ Returns the last element of the blockchain list. """
    if len(blockchain) < 1:
        return None
    return blockchain[-1]


def add_tx(recipient, sender=OWNER, amount=1.0):
    """ Adds a transaction to the blockchain
        and current transaction amount to the blockchain list.

        Parameters:

          <sender> The sender of the coins.
          <recipient> The recipient of the coins.
          <amount> The amount of coins transferred (default: 1.0).
    """
    # tx = {"sender": sender, "recipient": recipient, "amount": amount}
    tx = OrderedDict([("sender", sender), ("recipient", recipient), ("amount", amount)])
    if valid_tx(tx):
        open_txs.append(tx)
        participants.add(sender)
        participants.add(recipient)
        save_data()
        return True
    return False


def get_tx():
    """ Gets and returns user input (transaction amount)
        from the user as a float.
    """
    recipient = input("Please enter the recipient: ")
    amount = float(input("Please enter transaction amount: "))
    return recipient, amount
    # return (sender, recipient, amount)
    # return {"sender": sender, "recipient": recipient, "amount": amount}


def get_balance(participant):
    """ Gets and returns a participants balance. """
    deductions = [
        tx["amount"]
        for block in blockchain
        for tx in block["transactions"]
        if tx["sender"] == participant
    ]
    additions = [
        tx["amount"]
        for block in blockchain
        for tx in block["transactions"]
        if tx["recipient"] == participant
    ]
    open_deductions = [tx["amount"] for tx in open_txs if tx["sender"] == participant]
    open_additions = [tx["amount"] for tx in open_txs if tx["recipient"] == participant]
    print(
        f"[debug]: participant: {participant},",
        f"deductions: {deductions} (open: {open_deductions}),",
        f"additions: {additions} (open: {open_additions})",
    )
    return sum(additions) + sum(open_additions) - sum(deductions) - sum(open_deductions)

    # print(
    #     f"   participant: {participant:20}, open deductions: {open_deductions}, open additions: {open_additions}"
    # )
    # deduction_amts = [
    #     [tx["amount"] for tx in block["transactions"] if tx["sender"] == participant]
    #     for block in blockchain
    # ]
    # deductions = [v for l in deduction_amts for v in l]
    # addition_amts = [
    #     [tx["amount"] for tx in block["transactions"] if tx["recipient"] == participant]
    #     for block in blockchain
    # ]
    # additions = [v for l in addition_amts for v in l]
    # print(
    #     f"participant: {participant}, deduction_amts: {deduction_amts}, addition_amts: {addition_amts}"
    # )


def valid_tx(tx):
    sender_bal = get_balance(tx["sender"])
    return sender_bal >= tx["amount"]


def generate_guess_string(transactions, last_block_hash, proof):
    return POW_TEMPLATE.format(
        t=str(transactions), h=str(last_block_hash), p=str(proof)
    )


def valid_proof(transactions, last_block_hash, proof):
    # guess_str = str(transactions) + str(last_block_hash) + str(proof)
    guess_str = generate_guess_string(transactions, last_block_hash, proof)
    guess_str_encoded = guess_str.encode()
    # guess_hash = hashlib.sha256(guess_str_encoded).hexdigest()
    guess_hash = hash_utils.hash_string_256(guess_str_encoded)
    # print(f"[debug]: guess_str ({guess_str}) and guess_hash ({guess_hash})", end="\r")
    print(f"[debug]: guess_hash ({guess_hash})", end="\r")
    return guess_hash[0:POW_DIGITS] == POW_PATTERN


def proof_of_work(transactions, last_block_hash):
    proof = 0
    while not valid_proof(transactions, last_block_hash, proof):
        proof += 1
    print()
    print(
        f"[debug]: Proof of Work: found the proof ({proof}) that generated a",
        f"hash with the first {POW_DIGITS} digits matching the pattern",
        f"'{POW_PATTERN}'",
    )
    guess_str = generate_guess_string(transactions, last_block_hash, proof)
    print(f"[debug]: guess_str: ({guess_str})")
    return proof


def get_user_choice():
    """ Gets and returns user input (user choice) from the user. """
    return input("Please enter choice: ").upper()


def mine_block(open_txs):
    """ Adds a block of current transactions to the blockchain. """
    # reward the miner
    # reward_tx = {"sender": "MINING", "recipient": OWNER, "amount": MINING_REWARD}
    reward_tx = OrderedDict(
        [("sender", "MINING"), ("recipient", OWNER), ("amount", MINING_REWARD)]
    )
    new_txs = open_txs[:]  # make a copy in order to preserve open_txs
    new_txs.append(reward_tx)
    # add the current transactions
    last_block = blockchain[-1]
    last_block_hash = hash_utils.generate_hash(last_block)
    proof = proof_of_work(open_txs, last_block_hash)
    block = {
        "prev_block_hash": last_block_hash,
        "index": len(blockchain),
        "transactions": new_txs,
        "proof": proof,
    }
    blockchain.append(block)
    return True


def print_out_blockchain(blockchain):
    """ Prints out the blockchain. """
    print("The entire blockchain:")
    print(blockchain)
    print("Printing out the blocks...")
    i = 0
    for block in blockchain:
        print(f"  Block[{i}]: {block}")
        i += 1
    else:
        print("-" * 20)


def validate_blockchain(blockchain):
    """ Validates the blockchain. """
    is_valid = True
    print("Validating the blockchain...")
    for i, block in enumerate(blockchain):
        if i == 0:
            continue
        else:
            prev_block = blockchain[i - 1]
            prev_block_hash = hash_utils.generate_hash(prev_block)
            print(f"[debug]: Comparing current block[{i}] ({block})")
            print(f"[debug]:      and previous block[{i-1}] ({prev_block})")
            print(
                f"[debug]: Current block[prev_block_hash] == prev_block_hash",
                f"({block['prev_block_hash']} == {prev_block_hash})? ",
                end="",
            )
            if block["prev_block_hash"] == prev_block_hash:
                print(f"{GRN}Match!{NRM}")
            else:
                print(f"{RED}MIS-MATCH{NRM}!")
                is_valid = False
            print(f"[debug]: Verifying proof of block[{i}] ({block})")
            print(
                f"[debug]:   Comparing first {POW_DIGITS} digits",
                f"to match '{POW_PATTERN}' in the hash created from:",
            )
            transactions_without_mining_reward = block["transactions"][:-1]
            print(
                f"[debug]:   Transactions ({transactions_without_mining_reward}) last",
                f"block hash ({block['prev_block_hash']}) and proof",
                f"({block['proof']})",
            )
            if valid_proof(
                transactions_without_mining_reward,
                block["prev_block_hash"],
                block["proof"],
            ):
                proof_succeeded = True
            else:
                proof_succeeded = False
                is_valid = False
            print()
            # guess_str = (
            #     str(transactions_without_mining_reward)
            #     + str(block["prev_block_hash"])
            #     + str(block["proof"])
            # )
            guess_str = generate_guess_string(
                transactions_without_mining_reward,
                block["prev_block_hash"],
                block["proof"],
            )
            print(f"[debug]: guess_str: ({guess_str})")
            if proof_succeeded:
                print(f"[debug]:   Proof {GRN}Succeeded{NRM}!")
            else:
                print(f"[debug]:   Proof {RED}FAILED{NRM}!")
    return is_valid

    # print(
    #     f"[debug]: Comparing block[{i}] ({block})",
    #     f"hash ({block['prev_block_hash']})",
    # )
    # print(
    #     f"[debug]:   and previous block[{i-1}] ({blockchain[i-1]})",
    #     f"hash ({prev_block_hash})... ",
    #     end="",
    # )
    # for i in range(len(blockchain)):
    #     if i == 0:
    #         continue
    #     else:
    #         prev_block_hash = hash_utils.generate_hash(blockchain[i - 1])
    #         print(
    #             f"  Comparing block[{i}] ({blockchain[i]})",
    #             f"hash ({blockchain[i]['prev_block_hash']})",
    #         )
    #         print(
    #             f"    and previous block[{i-1}] ({blockchain[i-1]})",
    #             f"hash ({prev_block_hash})... ",
    #             end="",
    #         )
    #         if blockchain[i]["prev_block_hash"] == previous_block_hash:
    #             print("match")
    #         else:
    #             print("mis-match")
    #             is_valid = False


# first load any existing data
load_data()

# display menu and process user requests
more_input = True
while more_input:
    print("Please choose")
    print("  a: Add a transaction value")
    print("  b: Show balances")
    print("  c: Change the blockchain")
    print("  m: Mine the blockchain")
    print("  p: Print the blockchain blocks")
    print("  s: Show the participants")
    print("  v: Validate the blockchain")
    print("  q: Quit")
    usr_choice = get_user_choice()
    if usr_choice == "A":
        recipient, amount = get_tx()
        if add_tx(recipient, amount=amount):
            print(f"{GRN}Transaction succeded{NRM}!")
        else:
            print(f"{RED}Transaction failed{NRM}!")
        print(f"[debug]: All open transactions:\n{open_txs}")
    elif usr_choice == "B":
        for participant in participants:
            # print(f"{participant}:", get_balance(participant))
            print(
                f"   Balance - Owner: {participant:>15} [{get_balance(participant):10.2f}]"
            )
    elif usr_choice == "C":
        if len(blockchain) > 1:
            blockchain[1] = BOGUS_BLOCK
    elif usr_choice == "M":
        if mine_block(open_txs):
            open_txs = []
            save_data()
    elif usr_choice == "P":
        print_out_blockchain(blockchain)
    elif usr_choice == "S":
        print(participants)
    elif usr_choice == "V":
        validate_blockchain(blockchain)
    elif usr_choice == "Q":
        more_input = False
    else:
        print(f"Not a valid choice: '{usr_choice}'")
    # if not validate_blockchain(blockchain):
    #     print(f"Not a valid blockchain! Normally would exit here...")
    # print(f"Not a valid blockchain! Exiting...")
    # break
else:
    print("No more input")


print("Done!")
