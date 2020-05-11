# initialize/define the blockchain list
blockchain = []
open_txs = []


def get_last_blockchain_val():
    """ Returns the last element of the blockchain list. """
    if len(blockchain) < 1:
        return None
    return blockchain[-1]


def add_tx(tx_amt, last_tx=[1]):
    """ Adds the last transaction amount
        and current transaction amount to the blockchain list.

        Parameters:

          <tx_amt> current transaction amount.
          <last_tx> last transaction (default: [1]).
    """
    if last_tx is None:
        last_tx = [1]
    return blockchain.append([last_tx, tx_amt])


def get_tx_amt():
    """ Gets and returns user input (transaction amount)
        from the user as a float.
    """
    return float(input("Please enter transaction amount: "))


def get_user_choice():
    """ Gets and returns user input (user choice)
        from the user.
    """
    return input("Please enter choice: ").upper()


def mine_block():
    pass


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
    for i in range(len(blockchain)):
        if i == 0:
            continue
        else:
            print(
                f"  Comparing block[{i}] ({blockchain[i]})",
                f"first element ({blockchain[i][0]})",
            )
            print(f"    and previous block[{i-1}]", f"({blockchain[i-1]})... ", end="")
            if blockchain[i][0] == blockchain[i - 1]:
                print("match")
                is_valid = True
            else:
                print("mis-match")
                is_valid = False
                break
    # # --- original attempt ---
    # if len(blockchain) > 1:
    #     for i in range(1, len(blockchain)):
    #         print(
    #             f"  Comparing block[{i - 1}] ({blockchain[i - 1]})",
    #             f"and block[{i}][0] ({blockchain[i]})... ",
    #             end="",
    #         )
    #         if blockchain[i - 1] == blockchain[i][0]:
    #             print("match")
    #         else:
    #             print("mis-match")
    # # --- original attempt ---

    # # --- second attempt ---
    # i = 0
    # for block in blockchain:
    #     if i == 0:
    #         i += 1
    #         continue
    #     else:
    #         print(f"  Comparing block[{i}] ({block})", f"first element ({block[0]})")
    #         print(
    #             f"    and previous block[{i-1}] ({blockchain[(i-1)]})... ", end="",
    #         )
    #         if block[0] == blockchain[(i - 1)]:
    #             print("match")
    #             is_valid = True
    #         else:
    #             print("mis-match")
    #             is_valid = False
    #             break
    #         i += 1
    # # --- second attempt ---
    return is_valid


more_input = True

while more_input:
    print("Please choose")
    print("  a: Add a transaction value")
    print("  p: Print the blockchain blocks")
    print("  m: Manipulate the blockchain")
    print("  v: Validate the blockchain")
    print("  q: Quit")
    usr_choice = get_user_choice()
    if usr_choice == "A":
        tx_amt = get_tx_amt()
        add_tx(tx_amt, get_last_blockchain_val())
    elif usr_choice == "P":
        print_out_blockchain(blockchain)
    elif usr_choice == "M":
        if len(blockchain) > 0:
            blockchain[0] = [2]
    elif usr_choice == "V":
        validate_blockchain(blockchain)
    elif usr_choice == "Q":
        more_input = False
    else:
        print(f"Not a valid choice: '{usr_choice}'")
    # add_tx(last_tx=get_last_blockchain_val(), tx_amt=tx_amt)
    if not validate_blockchain(blockchain):
        print(f"Not a valid blockchain! Exiting...")
        break
else:
    print("No more input")


print("Done!")
