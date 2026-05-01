"""
Ownership Transfer Test — Member 2 (S7)
========================================
Proves that transferOwnership() works correctly on CharityCampaigns:
  1. Admin (accounts[0]) adds a campaign              → succeeds
  2. Admin calls transferOwnership(accounts[1])        → ownership moves
  3. Old admin (accounts[0]) tries to add a campaign   → reverts  → PASS
  4. New admin (accounts[1]) adds a campaign            → succeeds → PASS

Prerequisites
-------------
- Ganache running at http://127.0.0.1:7545
- deploy.py has been run (config.json + ABIs exist)
"""

import json
import sys
from web3 import Web3

# ---------------------------------------------------------------------------
#  Configuration
# ---------------------------------------------------------------------------
GANACHE_URL = "http://127.0.0.1:7545"

def load_config():
    """Load contract addresses and ABIs from config.json and abis/ folder."""
    with open("config.json", "r") as f:
        config = json.load(f)

    with open("abis/CharityCampaigns.json", "r") as f:
        charity_abi = json.load(f)

    return config, charity_abi


def main():
    # --- Connect to Ganache ---
    w3 = Web3(Web3.HTTPProvider(GANACHE_URL))
    if not w3.is_connected():
        print("ERROR: Cannot connect to Ganache at", GANACHE_URL)
        sys.exit(1)

    accounts = w3.eth.accounts
    if len(accounts) < 2:
        print("ERROR: Need at least 2 Ganache accounts")
        sys.exit(1)

    config, charity_abi = load_config()
    charity_address = config["CharityCampaigns"]

    contract = w3.eth.contract(
        address=Web3.to_checksum_address(charity_address),
        abi=charity_abi
    )

    original_admin = accounts[0]
    new_admin      = accounts[1]

    print("=" * 60)
    print("  Ownership Transfer Test")
    print("=" * 60)
    print(f"  Original Admin : {original_admin}")
    print(f"  New Admin      : {new_admin}")
    print("=" * 60)

    # ------------------------------------------------------------------
    # Step 1: Admin (accounts[0]) adds a campaign — should SUCCEED
    # ------------------------------------------------------------------
    print("\n[Step 1] Original admin adds a campaign...")
    try:
        tx_hash = contract.functions.addCampaign(
            "Test Campaign Before Transfer",
            "Testing admin action before ownership transfer",
            w3.to_wei(5, "ether")
        ).transact({"from": original_admin, "gas": 300000})
        w3.eth.wait_for_transaction_receipt(tx_hash)
        print("  ✅ PASS — Campaign added successfully by original admin")
    except Exception as e:
        print(f"  ❌ FAIL — Original admin could not add campaign: {e}")
        sys.exit(1)

    # ------------------------------------------------------------------
    # Step 2: Transfer ownership to accounts[1]
    # ------------------------------------------------------------------
    print("\n[Step 2] Transferring ownership to new admin...")
    try:
        tx_hash = contract.functions.transferOwnership(new_admin).transact({
            "from": original_admin,
            "gas": 100000
        })
        w3.eth.wait_for_transaction_receipt(tx_hash)
        current_admin = contract.functions.getAdmin().call()
        print(f"  ✅ Ownership transferred. Current admin: {current_admin}")
    except Exception as e:
        print(f"  ❌ FAIL — Could not transfer ownership: {e}")
        sys.exit(1)

    # ------------------------------------------------------------------
    # Step 3: Old admin tries to add a campaign — should REVERT
    # ------------------------------------------------------------------
    print("\n[Step 3] Old admin tries to add a campaign (should fail)...")
    try:
        tx_hash = contract.functions.addCampaign(
            "Should Fail Campaign",
            "This should be rejected",
            w3.to_wei(1, "ether")
        ).transact({"from": original_admin, "gas": 300000})
        w3.eth.wait_for_transaction_receipt(tx_hash)
        print("  ❌ FAIL — Old admin was able to add a campaign after transfer!")
    except Exception:
        print("  ✅ PASS — Old admin correctly blocked (transaction reverted)")

    # ------------------------------------------------------------------
    # Step 4: New admin adds a campaign — should SUCCEED
    # ------------------------------------------------------------------
    print("\n[Step 4] New admin adds a campaign (should succeed)...")
    try:
        tx_hash = contract.functions.addCampaign(
            "Test Campaign After Transfer",
            "Testing admin action after ownership transfer",
            w3.to_wei(10, "ether")
        ).transact({"from": new_admin, "gas": 300000})
        w3.eth.wait_for_transaction_receipt(tx_hash)
        print("  ✅ PASS — New admin added campaign successfully")
    except Exception as e:
        print(f"  ❌ FAIL — New admin could not add campaign: {e}")

    # ------------------------------------------------------------------
    # Summary
    # ------------------------------------------------------------------
    print("\n" + "=" * 60)
    print("  Ownership Transfer Test Complete")
    print("=" * 60)


if __name__ == "__main__":
    main()
