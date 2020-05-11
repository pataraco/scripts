# initialize/define globals
# constants
MINING_REWARD = 10
GENESIS_BLOCK = {
    "previous_hash": "",
    "index": 0,
    "transactions": [],
}
OWNER = "PAR"
BOGUS_TX = {"sender": "Someone", "recipient": OWNER, "amount": 100.0}
BOGUS_BLOCK = {"previous_hash": "", "index": 0, "transactions": [BOGUS_TX]}
# variables
blockchain = [GENESIS_BLOCK]
open_txs = []
participants = {OWNER}


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
    tx = {"sender": sender, "recipient": recipient, "amount": amount}
    if valid_tx(tx):
        open_txs.append(tx)
        participants.add(sender)
        participants.add(recipient)
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
        f"debug: participant: {participant}, deductions: {deductions} (open: {open_deductions}), additions: {additions} (open: {open_additions})"
    )
    # print(
    #     f"   participant: {participant:20}, open deductions: {open_deductions}, open additions: {open_additions}"
    # )
    return sum(additions) + sum(open_additions) - sum(deductions) - sum(open_deductions)
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


def get_user_choice():
    """ Gets and returns user input (user choice) from the user. """
    return input("Please enter choice: ").upper()


def generate_hash(block):
    """ Generates hash of a block in the blockchain. """
    # return '-'.join([str(block[key]) for key in block])
    return hash(str(block))


def mine_block(open_txs):
    """ Adds a block of current transactions to the blockchain. """
    # reward the miner
    reward_tx = {"sender": "MINING", "recipient": OWNER, "amount": MINING_REWARD}
    new_txs = open_txs[:]  # make a copy in order to preserve open_txs
    new_txs.append(reward_tx)
    # add the current transactions
    last_block = blockchain[-1]
    last_block_hash = generate_hash(last_block)
    block = {
        "previous_hash": last_block_hash,
        "index": len(blockchain),
        "transactions": new_txs,
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
            previous_block_hash = generate_hash(blockchain[i - 1])
            print(
                f"  Comparing block[{i}] ({block})", f"hash ({block['previous_hash']})",
            )
            print(
                f"    and previous block[{i-1}] ({blockchain[i-1]})",
                f"hash ({previous_block_hash})... ",
                end="",
            )
            if block["previous_hash"] == previous_block_hash:
                print("match")
            else:
                print("mis-match")
                is_valid = False
    return is_valid
    # for i in range(len(blockchain)):
    #     if i == 0:
    #         continue
    #     else:
    #         previous_block_hash = generate_hash(blockchain[i - 1])
    #         print(
    #             f"  Comparing block[{i}] ({blockchain[i]})",
    #             f"hash ({blockchain[i]['previous_hash']})",
    #         )
    #         print(
    #             f"    and previous block[{i-1}] ({blockchain[i-1]})",
    #             f"hash ({previous_block_hash})... ",
    #             end="",
    #         )
    #         if blockchain[i]["previous_hash"] == previous_block_hash:
    #             print("match")
    #         else:
    #             print("mis-match")
    #             is_valid = False


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
            print("Transaction succeded!")
        else:
            print("Transaction failed!")
        print(f"All open transactions:\n{open_txs}")
    elif usr_choice == "B":
        for participant in participants:
            # print(f"{participant}:", get_balance(participant))
            print(
                f"   Balance - Owner: {participant:>15} [{get_balance(participant):10.2f}]"
            )
    elif usr_choice == "C":
        if len(blockchain) > 0:
            blockchain[0] = BOGUS_BLOCK
    elif usr_choice == "M":
        if mine_block(open_txs):
            open_txs = []
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
