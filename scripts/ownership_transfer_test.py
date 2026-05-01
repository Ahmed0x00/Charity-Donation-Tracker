"""
Ownership Transfer Test
Tests that transferOwnership works on the CharityCampaigns contract.
Run this after deploy.py has been executed.
"""

import json
import sys
from web3 import Web3

GANACHE_URL = "http://127.0.0.1:7545"


def main():
    w3 = Web3(Web3.HTTPProvider(GANACHE_URL))
    if not w3.is_connected():
        print("Cannot connect to Ganache!")
        sys.exit(1)

    accounts = w3.eth.accounts

    # load config and abi
    with open("config.json") as f:
        config = json.load(f)
    with open("abis/CharityCampaigns.json") as f:
        abi = json.load(f)

    contract = w3.eth.contract(
        address=config["CharityCampaigns"],
        abi=abi
    )

    original_admin = accounts[0]
    new_admin = accounts[1]

    print("Ownership Transfer Test")
    print(f"Original admin: {original_admin}")
    print(f"New admin:      {new_admin}")
    print()

    # step 1 - original admin adds a campaign (should work)
    print("[1] Original admin adding a campaign...")
    try:
        tx = contract.functions.addCampaign(
            "Test Before Transfer", "testing", w3.to_wei(5, "ether")
        ).transact({"from": original_admin, "gas": 300000})
        w3.eth.wait_for_transaction_receipt(tx)
        print("    PASS - campaign added")
    except Exception as e:
        print(f"    FAIL - {e}")
        sys.exit(1)

    # step 2 - transfer ownership
    print("[2] Transferring ownership...")
    try:
        tx = contract.functions.transferOwnership(new_admin).transact({
            "from": original_admin, "gas": 100000
        })
        w3.eth.wait_for_transaction_receipt(tx)
        print(f"    Done. Admin is now: {contract.functions.getAdmin().call()}")
    except Exception as e:
        print(f"    FAIL - {e}")
        sys.exit(1)

    # step 3 - old admin tries again (should fail)
    print("[3] Old admin trying to add campaign (should fail)...")
    try:
        tx = contract.functions.addCampaign(
            "Should Fail", "nope", w3.to_wei(1, "ether")
        ).transact({"from": original_admin, "gas": 300000})
        w3.eth.wait_for_transaction_receipt(tx)
        print("    FAIL - old admin could still add!")
    except Exception:
        print("    PASS - old admin blocked")

    # step 4 - new admin tries (should work)
    print("[4] New admin adding a campaign...")
    try:
        tx = contract.functions.addCampaign(
            "Test After Transfer", "works now", w3.to_wei(10, "ether")
        ).transact({"from": new_admin, "gas": 300000})
        w3.eth.wait_for_transaction_receipt(tx)
        print("    PASS - new admin added campaign")
    except Exception as e:
        print(f"    FAIL - {e}")

    print("\nDone.")


if __name__ == "__main__":
    main()
