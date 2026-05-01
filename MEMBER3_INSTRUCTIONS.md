# Member 3 — Detailed Instructions

You have **3 tasks** to complete. All are Python scripts that interact with the smart contracts via `web3.py`.

> **Your work is on the critical path** — Members 4, 5, and 6 cannot start their scripts until you deploy the contracts and produce `config.json` + ABI files.

---

## Prerequisites

Before you start, make sure:

1. ✅ Python 3.8+ is installed
2. ✅ Dependencies installed: `pip install -r requirements.txt`
3. ✅ Ganache is running at `http://127.0.0.1:7545`
4. ✅ The Solidity contracts exist in `contracts/` (already done by Members 1 & 2)

---

## Task 1: `scripts/deploy.py` — Auto-Setup Script

**Grading checklist:** ✅ web3.py deployment ✅ send_transaction with gas ✅ ≥3 sample items

### What this script does

Compiles both Solidity contracts, deploys them to Ganache, seeds fake data, and saves everything so other scripts can use the contracts.

### Step-by-Step Implementation

```python
# 1. Install solc via py-solc-x
from solcx import install_solc, compile_standard
install_solc('0.8.0')

# 2. Read both .sol files
with open("contracts/CharityCampaigns.sol", "r") as f:
    charity_source = f.read()
with open("contracts/DonorCoin.sol", "r") as f:
    coin_source = f.read()

# 3. Compile using compile_standard()
compiled = compile_standard({
    "language": "Solidity",
    "sources": {
        "CharityCampaigns.sol": {"content": charity_source},
        "DonorCoin.sol": {"content": coin_source}
    },
    "settings": {
        "outputSelection": {
            "*": {"*": ["abi", "evm.bytecode"]}
        }
    }
}, solc_version="0.8.0")

# 4. Extract ABI and bytecode for each contract
charity_abi      = compiled["contracts"]["CharityCampaigns.sol"]["CharityCampaigns"]["abi"]
charity_bytecode = compiled["contracts"]["CharityCampaigns.sol"]["CharityCampaigns"]["evm"]["bytecode"]["object"]

coin_abi      = compiled["contracts"]["DonorCoin.sol"]["DonorCoin"]["abi"]
coin_bytecode = compiled["contracts"]["DonorCoin.sol"]["DonorCoin"]["evm"]["bytecode"]["object"]

# 5. Save ABIs to abis/ folder
import json, os
os.makedirs("abis", exist_ok=True)
with open("abis/CharityCampaigns.json", "w") as f:
    json.dump(charity_abi, f, indent=2)
with open("abis/DonorCoin.json", "w") as f:
    json.dump(coin_abi, f, indent=2)

# 6. Connect to Ganache
from web3 import Web3
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:7545"))
assert w3.is_connected(), "Cannot connect to Ganache!"
deployer = w3.eth.accounts[0]

# 7. Deploy CharityCampaigns
CharityCampaigns = w3.eth.contract(abi=charity_abi, bytecode=charity_bytecode)
tx_hash = CharityCampaigns.constructor().transact({
    "from": deployer,
    "gas": 3000000
})
receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
charity_address = receipt.contractAddress
print(f"CharityCampaigns deployed at: {charity_address}")

# 8. Deploy DonorCoin
DonorCoin = w3.eth.contract(abi=coin_abi, bytecode=coin_bytecode)
tx_hash = DonorCoin.constructor().transact({
    "from": deployer,
    "gas": 3000000
})
receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
coin_address = receipt.contractAddress
print(f"DonorCoin deployed at: {coin_address}")

# 9. Get contract instances
charity_contract = w3.eth.contract(address=charity_address, abi=charity_abi)
coin_contract    = w3.eth.contract(address=coin_address, abi=coin_abi)

# 10. Seed at least 3 fake campaigns
campaigns = [
    ("Clean Water Fund", "Providing clean water to rural communities", w3.to_wei(10, "ether")),
    ("Education for All", "Building schools in underserved areas", w3.to_wei(20, "ether")),
    ("Medical Aid Relief", "Emergency medical supplies for disaster zones", w3.to_wei(15, "ether")),
]
for name, desc, goal in campaigns:
    tx = charity_contract.functions.addCampaign(name, desc, goal).transact({
        "from": deployer,
        "gas": 300000
    })
    w3.eth.wait_for_transaction_receipt(tx)
    print(f"  Seeded campaign: {name}")

# 11. Mint some Donor Coins to test accounts
for i in range(1, 4):
    tx = coin_contract.functions.mint(
        w3.eth.accounts[i],
        w3.to_wei(100, "ether")  # 100 DNRC
    ).transact({"from": deployer, "gas": 100000})
    w3.eth.wait_for_transaction_receipt(tx)
    print(f"  Minted 100 DNRC to account {i}: {w3.eth.accounts[i]}")

# 12. Save config.json
config = {
    "CharityCampaigns": charity_address,
    "DonorCoin": coin_address
}
with open("config.json", "w") as f:
    json.dump(config, f, indent=2)
print(f"\nConfig saved to config.json")
print(f"  CharityCampaigns: {charity_address}")
print(f"  DonorCoin:        {coin_address}")
```

### Output Files

After running `deploy.py`, these files must exist:

| File | Content |
|------|---------|
| `abis/CharityCampaigns.json` | ABI array for CharityCampaigns contract |
| `abis/DonorCoin.json` | ABI array for DonorCoin contract |
| `config.json` | `{"CharityCampaigns": "0x...", "DonorCoin": "0x..."}` |

---

## Task 2: `scripts/admin_dashboard.py` — Admin Dashboard Script

**Grading checklist:** ✅ web3 block-range loop ✅ read contract view functions ✅ count transactions per sender ✅ formatted print output

### What this script does

Prints a summary of the entire system for the admin: total campaigns, total coins minted, total transactions, and top 3 most active addresses.

### Step-by-Step Implementation

```python
import json
from web3 import Web3

# 1. Connect to Ganache and load contracts
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:7545"))

with open("config.json") as f:
    config = json.load(f)
with open("abis/CharityCampaigns.json") as f:
    charity_abi = json.load(f)
with open("abis/DonorCoin.json") as f:
    coin_abi = json.load(f)

charity = w3.eth.contract(address=config["CharityCampaigns"], abi=charity_abi)
coin    = w3.eth.contract(address=config["DonorCoin"], abi=coin_abi)

# 2. Read campaign count from contract view function
campaign_count = charity.functions.campaignCount().call()

# 3. Read total supply from DonorCoin view function
total_supply = coin.functions.totalSupply().call()
total_supply_eth = w3.from_wei(total_supply, "ether")

# 4. Loop through all blocks and count transactions
total_tx = 0
sender_counts = {}
charity_addr = config["CharityCampaigns"].lower()
coin_addr    = config["DonorCoin"].lower()

latest_block = w3.eth.block_number
for block_num in range(0, latest_block + 1):
    block = w3.eth.get_block(block_num, full_transactions=True)
    for tx in block.transactions:
        # Count transactions TO either contract
        if tx["to"] and tx["to"].lower() in [charity_addr, coin_addr]:
            total_tx += 1
            sender = tx["from"]
            sender_counts[sender] = sender_counts.get(sender, 0) + 1

# 5. Find top 3 most active addresses
top_3 = sorted(sender_counts.items(), key=lambda x: x[1], reverse=True)[:3]

# 6. Print formatted summary
print("=" * 60)
print("          ADMIN DASHBOARD")
print("=" * 60)
print(f"  Total Campaigns   : {campaign_count}")
print(f"  Total Coins Minted: {total_supply_eth} DNRC")
print(f"  Total Transactions: {total_tx}")
print("-" * 60)
print("  Top 3 Most Active Addresses:")
for rank, (addr, count) in enumerate(top_3, 1):
    print(f"    {rank}. {addr} — {count} transactions")
print("=" * 60)
```

---

## Task 3: `scripts/balance_snapshot.py` — Balance Snapshot Exporter

**Grading checklist:** ✅ block iteration ✅ call balanceOf and get_balance per account ✅ Python csv module ✅ header row + one row per account

### What this script does

Scans every block on the chain, collects all unique addresses, queries their Donor Coin balance and ETH balance, then writes everything to a CSV file.

### Step-by-Step Implementation

```python
import json
import csv
import os
from web3 import Web3

# 1. Connect and load contracts
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:7545"))

with open("config.json") as f:
    config = json.load(f)
with open("abis/DonorCoin.json") as f:
    coin_abi = json.load(f)

coin = w3.eth.contract(address=config["DonorCoin"], abi=coin_abi)

# 2. Collect all unique addresses from block history
addresses = set()
latest_block = w3.eth.block_number
for block_num in range(0, latest_block + 1):
    block = w3.eth.get_block(block_num, full_transactions=True)
    for tx in block.transactions:
        addresses.add(tx["from"])
        if tx["to"]:
            addresses.add(tx["to"])

# 3. For each address: get balanceOf() and get_balance()
os.makedirs("exports", exist_ok=True)
output_file = "exports/balance_snapshot.csv"

with open(output_file, "w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    # Header row
    writer.writerow(["Account Address", "Donor Coin Balance", "ETH Balance"])

    for addr in sorted(addresses):
        try:
            coin_balance = coin.functions.balanceOf(addr).call()
            coin_balance_eth = float(w3.from_wei(coin_balance, "ether"))
        except:
            coin_balance_eth = 0.0

        eth_balance = w3.eth.get_balance(addr)
        eth_balance_eth = float(w3.from_wei(eth_balance, "ether"))

        writer.writerow([addr, f"{coin_balance_eth:.2f}", f"{eth_balance_eth:.2f}"])

print(f"Balance snapshot saved to {output_file}")
```

---

## How Other Members Depend on Your Work

Once you run `deploy.py`, the following files are created and used by everyone:

```
config.json                    → All scripts load contract addresses from here
abis/CharityCampaigns.json     → All scripts load the ABI from here
abis/DonorCoin.json            → All scripts load the ABI from here
```

**Every other member's script** starts with:

```python
with open("config.json") as f:
    config = json.load(f)
with open("abis/CharityCampaigns.json") as f:
    charity_abi = json.load(f)
```

So make sure `deploy.py` runs successfully and creates these files before telling the team to start!

---

## Testing Your Work

```bash
# 1. Make sure Ganache is running
# 2. Deploy everything
python scripts/deploy.py

# 3. Test the admin dashboard
python scripts/admin_dashboard.py

# 4. Test the balance snapshot
python scripts/balance_snapshot.py
cat exports/balance_snapshot.csv
```

All three scripts should run without errors. If they do, your tasks are complete! 🎉
