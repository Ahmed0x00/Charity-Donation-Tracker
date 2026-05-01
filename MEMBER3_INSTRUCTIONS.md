# Member 3 — Your Tasks

You are responsible for **3 Python scripts**. Your work is on the critical path — no one else can start their Python scripts until you finish `deploy.py`.

---

## Task 1: `scripts/deploy.py` — Auto-Setup Script

**What it does:** Compiles the two Solidity contracts, deploys them to Ganache, and seeds the blockchain with test data so the app is ready to use.

**What you need to do:**

1. Use `py-solc-x` to install the Solidity compiler (version 0.8.0) and compile both contracts (`CharityCampaigns.sol` and `DonorCoin.sol`)
2. Save the ABI (the JSON description of each contract's functions) to `abis/CharityCampaigns.json` and `abis/DonorCoin.json`
3. Connect to Ganache at `http://127.0.0.1:7545`
4. Deploy both contracts to the blockchain using `send_transaction` with an explicit `gas` parameter
5. Seed at least 3 fake charity campaigns by calling `addCampaign()` on the deployed contract
6. Mint some Donor Coins to a few test accounts by calling `mint()` on the DonorCoin contract
7. Save the deployed contract addresses to a `config.json` file so other scripts can find them
8. Print a summary of what was deployed

**Output files your script must create:**

| File | Content |
|------|---------|
| `abis/CharityCampaigns.json` | ABI for the CharityCampaigns contract |
| `abis/DonorCoin.json` | ABI for the DonorCoin contract |
| `config.json` | Contract addresses: `{"CharityCampaigns": "0x...", "DonorCoin": "0x..."}` |

**Grading checklist:** web3.py contract deployment, `send_transaction` with gas, at least 3 sample items inserted after deploy.

---

## Task 2: `scripts/admin_dashboard.py` — Admin Dashboard

**What it does:** Prints a summary of the whole system for the admin.

**What you need to do:**

1. Load the contract addresses from `config.json` and ABIs from the `abis/` folder
2. Read the total number of campaigns from the contract's `campaignCount()` view function
3. Read the total coins minted from the DonorCoin contract's `totalSupply()` view function
4. Loop through every block on the chain (from block 0 to the latest block) and count all transactions sent to the contract addresses
5. Track how many transactions each sender address made, then find the top 3 most active addresses
6. Print everything in a clean, formatted summary

**The output should show:**
- Total number of charity campaigns
- Total amount of Donor Coins minted
- Total number of transactions
- Top 3 most active user addresses

**Grading checklist:** web3 block-range loop, read contract view functions, count transactions per sender, formatted print output.

---

## Task 3: `scripts/balance_snapshot.py` — Balance Snapshot Exporter

**What it does:** Scans the blockchain, finds every address that has ever made a transaction, checks their balances, and saves it all to a CSV file.

**What you need to do:**

1. Loop through every block (block 0 to latest) and collect all unique addresses from transaction senders and receivers
2. For each address, query their Donor Coin balance using `balanceOf()` and their ETH balance using `web3.eth.get_balance()`
3. Convert balances to human-readable format using `from_wei`
4. Write everything to `exports/balance_snapshot.csv` using Python's `csv` module

**The CSV file must have:**
- A header row: `Account Address, Donor Coin Balance, ETH Balance`
- One row per unique address found on the chain

**Grading checklist:** block iteration, call `balanceOf` and `get_balance` per account, Python `csv` module, header row + one row per account.

---

## Important Notes

- All your scripts should load contract addresses from `config.json` and ABIs from the `abis/` folder
- Make sure Ganache is running before you execute anything
- Run `deploy.py` first — the other two scripts depend on the files it creates
- Use `try/except` around blockchain calls to handle errors gracefully
