from flask import Flask, jsonify, request, send_from_directory
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
    return send_from_directory("ui", "node.html")


@app.route("/balance", methods=["GET"])
def get_balance():
    funds = blockchain.get_balance(blockchain.hosting_node)
    if funds is not None:
        response = {
            "message": "Get balance succeeded",
            "funds": funds,
            "wallet_set_up": wallet.public_key is not None,
        }
        return jsonify(response), 201  # Created
    else:
        response = {
            "message": "Get balance failed",
            "wallet_set_up": wallet.public_key is not None,
        }
        return jsonify(response), 500  # Internal Server Error


@app.route("/chain", methods=["GET"])
def get_chain():
    chain_snaphot = blockchain.chain
    chain_dict = [b.__dict__.copy() for b in chain_snaphot]
    for chain_block in chain_dict:
        chain_block["transactions"] = [t.__dict__ for t in chain_block["transactions"]]
    return jsonify(chain_dict), 200  # OK
    # chain_dict = [
    #     b.__dict__
    #     for b in [
    #         Block(
    #             bce.index,
    #             bce.prev_block_hash,
    #             bce.proof,
    #             [t.__dict__ for t in bce.transactions],
    #             bce.timestamp,
    #         )
    #         for bce in chain_snaphot
    #     ]
    # ]


@app.route("/mine", methods=["POST"])
def mine():
    block = blockchain.mine_block()
    if block is not None:
        block_dict = block.__dict__.copy()
        block_dict["transactions"] = [t.__dict__ for t in block_dict["transactions"]]
        response = {
            "message": "Mining succeeded",
            "block": block_dict,
            "funds": blockchain.get_balance(blockchain.hosting_node),
            "wallet_set_up": wallet.public_key is not None,
        }
        return jsonify(response), 201  # Created
    else:
        response = {
            "message": "Mining failed",
            "wallet_set_up": wallet.public_key is not None,
        }
        return jsonify(response), 500  # Internal Server Error


@app.route("/transaction", methods=["POST"])
def add_transaction():
    sender = blockchain.hosting_node
    if sender is None:
        response = {
            "message": "No wallet set up",
            "wallet_set_up": wallet.public_key is not None,
        }
        return jsonify(response), 400  # Bad request
    values = request.get_json()
    if not values:
        response = {
            "message": "No data found",
            "wallet_set_up": wallet.public_key is not None,
        }
        return jsonify(response), 400  # Bad request
    required_fields = ["recipient", "amount"]
    if not all(f in values for f in required_fields):
        response = {
            "message": "Missing data",
            "wallet_set_up": wallet.public_key is not None,
        }
        return jsonify(response), 400  # Bad request
    recipient = values["recipient"]
    amount = values["amount"]
    signature = wallet.sign_tx(sender, recipient, amount)
    if blockchain.add_tx(sender, recipient, signature, amount):
        response = {
            "message": "Transaction add succeeded",
            "transaction": {
                "sender": sender,
                "recipient": recipient,
                "signature": signature,
                "amount": amount,
            },
            "funds": blockchain.get_balance(blockchain.hosting_node),
            "wallet_set_up": wallet.public_key is not None,
        }
        return jsonify(response), 201  # Created
    else:
        response = {
            "message": "Transaction add failed",
            "wallet_set_up": wallet.public_key is not None,
        }
        return jsonify(response), 500  # Internal Server Error


@app.route("/transactions", methods=["GET"])
def get_transactions():
    open_txs = blockchain.get_open_txs()
    transactions_dict = [t.__dict__ for t in open_txs]
    return jsonify(transactions_dict), 200  # OK
    # if open_txs:
    #     transactions_dict = [t.__dict__ for t in open_txs]
    #     response = {
    #         "message": "Open transactions retrievel succeeded",
    #         "open_transactions": transactions_dict,
    #         "wallet_set_up": wallet.public_key is not None,
    #     }
    #     return jsonify(response), 200  # OK
    # else:
    #     transactions_dict = [t.__dict__ for t in open_txs]
    #     response = {
    #         "message": "No open transactions",
    #         "open_transactions": transactions_dict,
    #         "wallet_set_up": wallet.public_key is not None,
    #     }
    #     return jsonify(response), 200  # OK


@app.route("/create-wallet", methods=["POST"])
def create_keys():
    if wallet.create_keys():
        global blockchain
        blockchain = Blockchain(wallet.public_key)
        response = {
            "message": "Wallet creation succeeded",
            "public_key": wallet.public_key,
            "private_key": wallet.private_key,
            "funds": blockchain.get_balance(blockchain.hosting_node),
            "wallet_set_up": wallet.public_key is not None,
        }
        return jsonify(response), 201  # Created
    else:
        response = {
            "message": "Wallet creation failed",
            "wallet_set_up": wallet.public_key is not None,
        }
        return jsonify(response), 500  # Internal Server Error


@app.route("/load-wallet", methods=["GET"])
def load_keys():
    if wallet.load_keys():
        global blockchain
        blockchain = Blockchain(wallet.public_key)
        response = {
            "message": "Wallet load succeeded",
            "public_key": wallet.public_key,
            "private_key": wallet.private_key,
            "funds": blockchain.get_balance(blockchain.hosting_node),
            "wallet_set_up": wallet.public_key is not None,
        }
        return jsonify(response), 200  # OK
    else:
        response = {
            "message": "Wallet load failed",
            "wallet_set_up": wallet.public_key is not None,
        }
        return jsonify(response), 500  # Internal Server Error


@app.route("/save-wallet", methods=["POST"])
def save_keys():
    if wallet.save_keys():
        response = {
            "message": "Wallet save succeeded",
            "wallet_set_up": wallet.public_key is not None,
        }
        return jsonify(response), 201  # Created
    else:
        response = {
            "message": "Wallet save failed",
            "wallet_set_up": wallet.public_key is not None,
        }
        return jsonify(response), 500  # Internal Server Error


@app.route("/node", methods=["POST"])
def add_node():
    values = request.get_json()
    if not values:
        response = {
            "message": "No data found",
        }
        return jsonify(response), 400  # Bad request
    if "node" not in values:
        response = {
            "message": "No node data found",
        }
        return jsonify(response), 400  # Bad request
    node = values.get("node")
    blockchain.add_peer_node(node)
    response = {
        "message": "Node add succeeded",
        "all_nodes": blockchain.get_peer_nodes(),
    }
    return jsonify(response), 201  # Created


@app.route("/node/<node_url>", methods=["DELETE"])
def remove_node(node_url):
    if node_url == "" or node_url is None:
        response = {
            "message": "No node found",
        }
        return jsonify(response), 400  # Bad request
    blockchain.remove_peer_node(node_url)
    response = {
        "message": "Node remove succeeded",
        "all_nodes": blockchain.get_peer_nodes(),
    }
    return jsonify(response), 202  # Accepted


@app.route("/nodes", methods=["GET"])
def get_peer_nodes():
    all_nodes = blockchain.get_peer_nodes()
    response = {"message": "Get peer nodes succeeded", "all_nodes": all_nodes}
    return jsonify(response), 200  # OK


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
