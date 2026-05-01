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

**Step 1 — Import everything you need:**

```python
import json
import os
from web3 import Web3
from solcx import install_solc, compile_source
```

**Step 2 — Install the Solidity compiler:**

```python
install_solc('0.8.0')
```

This downloads the Solidity compiler version 0.8.0 to your machine. It only needs to download once.

**Step 3 — Read the contract files:**

```python
with open("contracts/CharityCampaigns.sol", "r") as f:
    charity_source = f.read()

with open("contracts/DonorCoin.sol", "r") as f:
    coin_source = f.read()
```

**Step 4 — Compile the contracts:**

`compile_source()` takes the Solidity code as a string and returns compiled output (ABI + bytecode).

```python
# Compile CharityCampaigns
charity_compiled = compile_source(
    charity_source,
    output_values=["abi", "bin"],
    solc_version="0.8.0"
)
# The key is "<stdin>:CharityCampaigns" — we grab the contract by name
charity_data = charity_compiled["<stdin>:CharityCampaigns"]
charity_abi = charity_data["abi"]
charity_bytecode = charity_data["bin"]

# Compile DonorCoin
coin_compiled = compile_source(
    coin_source,
    output_values=["abi", "bin"],
    solc_version="0.8.0"
)
coin_data = coin_compiled["<stdin>:DonorCoin"]
coin_abi = coin_data["abi"]
coin_bytecode = coin_data["bin"]
```

**What is ABI?** The ABI (Application Binary Interface) is a JSON list that describes all the functions and events in your contract. Python needs this to know how to call the contract.

**What is bytecode?** The compiled machine code that gets deployed to the blockchain.

**Step 5 — Save the ABIs to files:**

Other team members' scripts will load these files to interact with the contracts.

```python
os.makedirs("abis", exist_ok=True)

with open("abis/CharityCampaigns.json", "w") as f:
    json.dump(charity_abi, f, indent=2)

with open("abis/DonorCoin.json", "w") as f:
    json.dump(coin_abi, f, indent=2)

print("ABIs saved to abis/ folder")
```

**Step 6 — Connect to Ganache:**

```python
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:7545"))

if not w3.is_connected():
    print("ERROR: Cannot connect to Ganache! Make sure it is running.")
    exit()

print("Connected to Ganache")
deployer = w3.eth.accounts[0]   # First account is the deployer/admin
print(f"Deployer account: {deployer}")
```

**Step 7 — Deploy CharityCampaigns contract:**

```python
CharityCampaigns = w3.eth.contract(abi=charity_abi, bytecode=charity_bytecode)

tx_hash = CharityCampaigns.constructor().transact({
    "from": deployer,
    "gas": 3000000
})
receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
charity_address = receipt.contractAddress
print(f"CharityCampaigns deployed at: {charity_address}")
```

**Step 8 — Deploy DonorCoin contract:**

```python
DonorCoin = w3.eth.contract(abi=coin_abi, bytecode=coin_bytecode)

tx_hash = DonorCoin.constructor().transact({
    "from": deployer,
    "gas": 3000000
})
receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
coin_address = receipt.contractAddress
print(f"DonorCoin deployed at: {coin_address}")
```

**Step 9 — Get contract instances (so we can call functions):**

```python
charity_contract = w3.eth.contract(address=charity_address, abi=charity_abi)
coin_contract = w3.eth.contract(address=coin_address, abi=coin_abi)
```

**Step 10 — Seed at least 3 fake campaigns:**

```python
campaigns = [
    ("Clean Water Fund", "Providing clean water to rural communities", w3.to_wei(10, "ether")),
    ("Education for All", "Building schools in underserved areas", w3.to_wei(20, "ether")),
    ("Medical Aid Relief", "Emergency medical supplies for disaster zones", w3.to_wei(15, "ether")),
]

for name, desc, goal in campaigns:
    tx_hash = charity_contract.functions.addCampaign(name, desc, goal).transact({
        "from": deployer,
        "gas": 300000
    })
    w3.eth.wait_for_transaction_receipt(tx_hash)
    print(f"  Added campaign: {name}")
```

**Step 11 — Mint some Donor Coins to test accounts:**

```python
for i in range(1, 4):
    account = w3.eth.accounts[i]
    tx_hash = coin_contract.functions.mint(
        account,
        w3.to_wei(100, "ether")   # 100 DNRC tokens
    ).transact({
        "from": deployer,
        "gas": 100000
    })
    w3.eth.wait_for_transaction_receipt(tx_hash)
    print(f"  Minted 100 DNRC to account[{i}]: {account}")
```

**Step 12 — Save contract addresses to config.json:**

```python
config = {
    "CharityCampaigns": charity_address,
    "DonorCoin": coin_address
}

with open("config.json", "w") as f:
    json.dump(config, f, indent=2)

print("\nDone! Contract addresses saved to config.json:")
print(f"  CharityCampaigns: {charity_address}")
print(f"  DonorCoin:        {coin_address}")
```

### What gets created after running deploy.py

| File | What's inside |
|------|---------------|
| `abis/CharityCampaigns.json` | JSON list of all functions/events in CharityCampaigns |
| `abis/DonorCoin.json` | JSON list of all functions/events in DonorCoin |
| `config.json` | The blockchain addresses where the contracts live |

---

## Task 2: `scripts/admin_dashboard.py` — Admin Dashboard Script

**Grading checklist:** ✅ web3 block-range loop ✅ read contract view functions ✅ count transactions per sender ✅ formatted print output

### What this script does

Prints a summary for the admin: total campaigns, total coins minted, total transactions, and top 3 most active addresses.

### Full Code

```python
import json
from web3 import Web3

# --- Connect to Ganache ---
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:7545"))

# --- Load contract addresses and ABIs ---
with open("config.json") as f:
    config = json.load(f)

with open("abis/CharityCampaigns.json") as f:
    charity_abi = json.load(f)

with open("abis/DonorCoin.json") as f:
    coin_abi = json.load(f)

charity = w3.eth.contract(address=config["CharityCampaigns"], abi=charity_abi)
coin = w3.eth.contract(address=config["DonorCoin"], abi=coin_abi)

# --- Read data from contract view functions ---
campaign_count = charity.functions.campaignCount().call()
total_supply = coin.functions.totalSupply().call()
total_supply_display = w3.from_wei(total_supply, "ether")

# --- Scan all blocks to count transactions ---
total_tx = 0
sender_counts = {}

# These are the contract addresses we want to track
charity_addr = config["CharityCampaigns"].lower()
coin_addr = config["DonorCoin"].lower()

latest_block = w3.eth.block_number

for block_num in range(0, latest_block + 1):
    block = w3.eth.get_block(block_num, full_transactions=True)

    for tx in block.transactions:
        # Only count transactions sent TO our contracts
        if tx["to"] and tx["to"].lower() in [charity_addr, coin_addr]:
            total_tx += 1
            sender = tx["from"]
            sender_counts[sender] = sender_counts.get(sender, 0) + 1

# --- Find top 3 most active addresses ---
sorted_senders = sorted(sender_counts.items(), key=lambda x: x[1], reverse=True)
top_3 = sorted_senders[:3]

# --- Print formatted summary ---
print("=" * 60)
print("              ADMIN DASHBOARD")
print("=" * 60)
print(f"  Total Campaigns    : {campaign_count}")
print(f"  Total Coins Minted : {total_supply_display} DNRC")
print(f"  Total Transactions : {total_tx}")
print("-" * 60)
print("  Top 3 Most Active Addresses:")
for rank, (addr, count) in enumerate(top_3, 1):
    print(f"    {rank}. {addr} — {count} transactions")
if not top_3:
    print("    (no transactions yet)")
print("=" * 60)
```

---

## Task 3: `scripts/balance_snapshot.py` — Balance Snapshot Exporter

**Grading checklist:** ✅ block iteration ✅ call balanceOf and get_balance per account ✅ Python csv module ✅ header row + one row per account

### What this script does

Scans every block, collects all addresses that ever sent or received a transaction, checks their Donor Coin balance and ETH balance, and saves it all to a CSV file.

### Full Code

```python
import json
import csv
import os
from web3 import Web3

# --- Connect to Ganache ---
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:7545"))

# --- Load DonorCoin contract ---
with open("config.json") as f:
    config = json.load(f)

with open("abis/DonorCoin.json") as f:
    coin_abi = json.load(f)

coin = w3.eth.contract(address=config["DonorCoin"], abi=coin_abi)

# --- Step 1: Scan every block and collect all unique addresses ---
addresses = set()
latest_block = w3.eth.block_number

for block_num in range(0, latest_block + 1):
    block = w3.eth.get_block(block_num, full_transactions=True)
    for tx in block.transactions:
        addresses.add(tx["from"])         # sender
        if tx["to"]:
            addresses.add(tx["to"])       # receiver

print(f"Found {len(addresses)} unique addresses")

# --- Step 2: Query balances and write to CSV ---
os.makedirs("exports", exist_ok=True)
output_file = "exports/balance_snapshot.csv"

with open(output_file, "w", newline="") as csvfile:
    writer = csv.writer(csvfile)

    # Header row
    writer.writerow(["Account Address", "Donor Coin Balance", "ETH Balance"])

    # One row per account
    for addr in sorted(addresses):
        # Get Donor Coin balance
        try:
            coin_balance = coin.functions.balanceOf(addr).call()
            coin_display = float(w3.from_wei(coin_balance, "ether"))
        except:
            coin_display = 0.0

        # Get ETH balance
        eth_balance = w3.eth.get_balance(addr)
        eth_display = float(w3.from_wei(eth_balance, "ether"))

        writer.writerow([addr, f"{coin_display:.2f}", f"{eth_display:.2f}"])

print(f"Balance snapshot saved to {output_file}")
```

---

## How to Test Your Work

```bash
# 1. Make sure Ganache is running on port 7545
# 2. Deploy everything
python scripts/deploy.py

# 3. Test the admin dashboard
python scripts/admin_dashboard.py

# 4. Test the balance snapshot
python scripts/balance_snapshot.py
cat exports/balance_snapshot.csv
```

All three scripts should run without errors. If they do, your tasks are complete! 🎉
