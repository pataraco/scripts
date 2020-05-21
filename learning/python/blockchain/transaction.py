from collections import OrderedDict


class Transaction:
    """A transaction which can be added to a block in the blockchain.

    Attributes:
        <sender> The sender of the coins.
        <recipient> The recipient of the coins.
        <signature> The signature of the transaction.
        <ammount> The amount of coins sent.
    """

    def __init__(self, sender, recipient, signature, amount):
        self.sender = sender
        self.recipient = recipient
        self.signature = signature
        self.amount = amount

    def __repr__(self):
        return str(self.__dict__)
        # return (
        #     f"sender:{self.sender}"
        #     + f"|recipient:{self.recipient}"
        #     + f"|amount:{self.amount}"
        # )

    def to_ordered_dict(self):
        return OrderedDict(
            [
                ("sender", self.sender),
                ("recipient", self.recipient),
                ("amount", self.amount),
            ]
        )
