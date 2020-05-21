from flask import Flask, jsonify
from flask_cors import CORS
from blockchain import Blockchain
from block import Block
from wallet import Wallet

app = Flask(__name__)
wallet = Wallet()
blockchain = Blockchain(wallet.public_key)
CORS(app)


@app.route("/", methods=["GET"])
def get_ui():
    return "this is working!"


@app.route("/chain", methods=["GET"])
def get_chain():
    chain_snaphot = blockchain.chain
    chain_dict = [
        b.__dict__
        for b in [
            Block(
                bce.index,
                bce.prev_block_hash,
                bce.proof,
                [t.__dict__ for t in bce.transactions],
                bce.timestamp,
            )
            for bce in chain_snaphot
        ]
    ]
    return jsonify(chain_dict), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
