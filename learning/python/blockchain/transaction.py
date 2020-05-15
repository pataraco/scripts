from collections import OrderedDict


class Transaction:
    def __init__(self, sender, recipient, amount):
        self.sender = sender
        self.recipient = recipient
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
