from Crypto.PublicKey import RSA
from Crypto.Signature import PKCS1_v1_5
from Crypto.Hash import SHA256
import Crypto.Random
import binascii
import json
import sys


class Wallet:
    __MINING_OWNER = "MINING"
    __SAVE_FILE = "wallet-{}.txt"  # format with port

    def __init__(self, hosting_node_port):
        self.private_key = None
        self.public_key = None
        self.hosting_port = hosting_node_port

    def create_keys(self):
        private_key, public_key = self.generate_keys()
        self.private_key = private_key
        self.public_key = public_key
        return True

    def save_keys(self):
        if self.public_key is not None and self.private_key is not None:
            try:
                with open(self.__SAVE_FILE.format(self.hosting_port), mode="w") as f:
                    _data = {
                        "public_key": self.public_key,
                        "private_key": self.private_key,
                    }
                    f.write(json.dumps(_data))
            except IOError as e:
                print(f"[debug]: IOError: {e}")
                print(
                    f"IOError: trying to save wallet data to file: {self.__SAVE_FILE.format(self.hosting_port)}"
                )
                return False
            except Exception as e:
                print(f"[debug]: Exception (Catch All): {e}")
                print(f"[debug]: Error [{e.__class__.__name__}] ({e.__class__})")
                sys.exit(f"exit: error: {e}: not able to save wallet data")
                return False
            else:
                print(
                    f"[debug]: successfully saved wallet data to file: {self.__SAVE_FILE.format(self.hosting_port)}"
                )
                return True
        else:
            print(f"[debug]: not saving wallet data: None")
            return False

    def load_keys(self):
        try:
            with open(self.__SAVE_FILE.format(self.hosting_port), mode="r") as f:
                _data = json.loads(f.readline())  # dict: public & private keys
                self.public_key = _data["public_key"]
                self.private_key = _data["private_key"]
        except (IOError, IndexError) as e:
            print(f"[debug]: IOError|IndexError: {e}")
            print(
                f"IOError|IndexError: trying to load wallet data",
                f"by reading file: {self.__SAVE_FILE.format(self.hosting_port)}",
            )
            return False
        except Exception as e:
            print(f"[debug]: Exception (Catch All): {e}")
            print(f"[debug]: Error [{e.__class__.__name__}] ({e.__class__})")
            sys.exit(f"exit: error: {e}: not able to load wallet data")
            return False
        else:
            print(
                f"[debug]: successfully loaded wallet data",
                f"from file: {self.__SAVE_FILE.format(self.hosting_port)}",
            )
            return True

    def generate_keys(self):
        private_key = RSA.generate(1024, Crypto.Random.new().read)
        public_key = private_key.publickey()
        private_hex = binascii.hexlify(private_key.exportKey(format="DER")).decode(
            "ascii"
        )
        public_hex = binascii.hexlify(public_key.exportKey(format="DER")).decode(
            "ascii"
        )
        return (private_hex, public_hex)

    def sign_tx(self, sender, recipient, amount):
        private_key = RSA.importKey(binascii.unhexlify(self.private_key))
        signer = PKCS1_v1_5.new(private_key)
        hash_tx_payload = SHA256.new(
            (str(sender) + str(recipient) + str(amount)).encode("utf8")
        )
        signature = signer.sign(hash_tx_payload)
        sig_hex = binascii.hexlify(signature).decode("ascii")
        return sig_hex

    @classmethod
    def verify_tx(cls, transaction):
        """Verfify the signature of a transaction.
        Arguments:
            <transaction> The transaction that should be verified.
        """
        # this opens up a vulnerability
        # if transaction.sender == cls.__MINING_OWNER:
        #     return True
        public_key = RSA.importKey(binascii.unhexlify(transaction.sender))
        verifier = PKCS1_v1_5.new(public_key)
        hash_tx_payload = SHA256.new(
            (
                str(transaction.sender)
                + str(transaction.recipient)
                + str(transaction.amount)
            ).encode("utf8")
        )
        return verifier.verify(
            hash_tx_payload, binascii.unhexlify(transaction.signature)
        )
