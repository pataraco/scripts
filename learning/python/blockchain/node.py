from uuid import uuid4
from block import Block
from blockchain import Blockchain
from transaction import Transaction
from wallet import Wallet
from utility.verification import Verification
from os import environ

# global constants
POW_DIGITS = 3  # number of digits for Proof of Work (starting at 0)
BOGUS_TX = Transaction("Someone", str(uuid4()), None, 100.0)
BOGUS_BLOCK = Block(0, "", POW_DIGITS, [BOGUS_TX], 0)

# ASCII escape sequences
BLU = "\x1b[1;34m"  # blue, bold
D2E = "\x1b[0K"  # delete to EOL
GRN = "\x1b[1;32m"  # green, bold
NRM = "\x1b[m"  # normal
RED = "\x1b[1;31m"  # red, bold
YLW = "\x1b[1;33m"  # red, bold


class Node:
    def __init__(self):
        self.wallet = Wallet()
        self.wallet.create_keys()
        # self.id = str(uuid4())
        # self.id = environ["USER"]  # for dev only
        self.id = self.wallet.public_key
        self.blockchain = Blockchain(self.id)

    def get_tx(self):
        """ Gets and returns user input (transaction amount)
            from the user as a float.
        """
        recipient = input("Please enter the recipient: ")
        amount = float(input("Please enter transaction amount: "))
        return recipient, amount
        # return (sender, recipient, amount)
        # return {"sender": sender, "recipient": recipient, "amount": amount}

    def get_user_choice(self):
        """ Gets and returns user input (user choice) from the user. """
        return input("Please enter choice: ").upper()

    def listen_for_input(self):
        """ Displays a menu and processes user requests. """

        # display menu and process user requests
        more_input = True
        while more_input:
            print("Please choose")
            print("  a: Add a transaction value")
            print("  b: Show balances")
            print("  c: Corrupt the blockchain")
            print("  m: Mine the blockchain")
            print("  p: Print the blockchain blocks")
            print("  s: Show the participants")
            print("  vb: Validate the blockchain")
            print("  vo: Validate [all] open transactions")
            print("  cw: Create Wallet")
            print("  lw: Load Wallet")
            print("  sw: Save Wallet")
            print("  q: Quit")
            usr_choice = self.get_user_choice()
            if usr_choice == "A":
                recipient, amount = self.get_tx()
                signature = self.wallet.sign_tx(self.id, recipient, amount)
                if self.blockchain.add_tx(self.id, recipient, signature, amount=amount):
                    print(f"{GRN}Transaction succeeded{NRM}!")
                else:
                    print(f"{RED}Transaction failed{NRM}!")
                print(
                    f"[debug]: All open transactions:\n",
                    f"{self.blockchain.get_open_txs()}",
                )
            elif usr_choice == "B":
                for participant in sorted(self.blockchain.get_participants()):
                    print(
                        f"   Balance - Owner: {YLW}{participant:>15}{NRM}",
                        f"[{self.blockchain.get_balance(participant):10.2f}]",
                    )
            elif usr_choice == "C":
                self.blockchain.corrupt_chain()
            elif usr_choice == "M":
                if self.blockchain.mine_block():
                    print(f"{GRN}Mining succeeded{NRM}!")
                else:
                    print(f"{RED}Mining failed{NRM}! Do you have your wallet?")
            elif usr_choice == "P":
                self.print_out_blockchain()
            elif usr_choice == "S":
                print(self.blockchain.get_participants())
            elif usr_choice == "VO":
                if Verification.validate_txs(
                    self.blockchain.get_open_txs(), self.blockchain.get_balance
                ):
                    print("All open transactions are valid")
                else:
                    print("Some transactions are NOT valid")
            elif usr_choice == "VB":
                Verification.validate_blockchain(self.blockchain.get_chain())
            elif usr_choice == "CW":
                self.wallet.create_keys()
                self.id = self.wallet.public_key
                self.blockchain.hosting_node = self.id
                print(f"[debug]: public ID created: {self.id}")
            elif usr_choice == "LW":
                self.wallet.load_keys()
                self.id = self.wallet.public_key
                self.blockchain.hosting_node = self.id
                print(f"[debug]: public ID loaded: {self.id}")
            elif usr_choice == "SW":
                self.wallet.save_keys()
            elif usr_choice == "Q":
                more_input = False
            else:
                print(f"Not a valid choice: '{usr_choice}'")
            # if not Verification.validate_blockchain(blockchain.get_chain()):
            #     print(f"Not a valid blockchain! Normally would exit here...")
            #     print(f"Not a valid blockchain! Exiting...")
            #     break
        else:
            print("No more input")

        print("Done!")

    def print_out_blockchain(self):
        """ Prints out the blockchain. """
        print("The entire blockchain:")
        print(self.blockchain.get_chain())
        print("Printing out the blocks...")
        i = 0
        for block in self.blockchain.get_chain():
            print(f"  Block[{i}]: {block}")
            i += 1
        else:
            print("-" * 20)


if __name__ == "__main__":
    node = Node()
    node.listen_for_input()
