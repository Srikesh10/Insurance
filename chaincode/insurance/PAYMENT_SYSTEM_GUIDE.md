# 💰 Payment System Guide - Insurance Chaincode

## Overview

The insurance chaincode now includes a **complete payment system** that enables actual fund transfers during payouts. When `ExecuteTier1Payout()` or `ExecuteTier2Payout()` is called, money is **actually transferred** from the insurer's account to the client's account, and the transaction is permanently recorded on the blockchain.

---

## 🆕 New Data Structures

### **Account**
```go
type Account struct {
    AccountID string    // e.g., "account_AcmeInsurance"
    Owner     string    // MSP ID of owning organization
    Balance   float64   // Current balance
    CreatedAt time.Time // Account creation timestamp
}
```

### **Transaction**
```go
type Transaction struct {
    TxID      string    // Transaction ID from blockchain
    From      string    // Source account ID
    To        string    // Destination account ID
    Amount    float64   // Transfer amount
    Timestamp time.Time // Transaction timestamp
    Purpose   string    // e.g., "Tier1Payout", "Tier2Payout"
    ClaimID   string    // Optional: linked claim ID
}
```

---

## 📋 New Functions

### **1. CreateAccount(accountId, owner, initialBalance)**

Creates a new account with an initial balance.

**Parameters:**
- `accountId` (string): Unique account identifier (use pattern `account_<orgName>`)
- `owner` (string): MSP ID of the owning organization
- `initialBalance` (float64): Starting balance (must be >= 0)

**Example:**
```bash
peer chaincode invoke \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["CreateAccount","account_AcmeInsurance","InsurerOrgMSP","500000"]}'
```

---

### **2. GetAccount(accountId)**

Retrieves account details including balance.

**Parameters:**
- `accountId` (string): Account identifier

**Returns:** Account JSON object

**Example:**
```bash
peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetAccount","account_AcmeInsurance"]}'
```

**Response:**
```json
{
  "accountId": "account_AcmeInsurance",
  "owner": "InsurerOrgMSP",
  "balance": 500000.00,
  "createdAt": "2025-11-06T01:00:00Z"
}
```

---

### **3. GetBalance(accountId)**

Returns only the balance of an account.

**Parameters:**
- `accountId` (string): Account identifier

**Returns:** Balance (float64)

**Example:**
```bash
peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetBalance","account_AcmeInsurance"]}'
```

**Response:**
```json
500000.00
```

---

### **4. GetAllAccounts()**

Retrieves all accounts in the system (for demo purposes).

**Example:**
```bash
peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetAllAccounts"]}'
```

---

### **5. Transfer(fromAccountId, toAccountId, amount, purpose, claimId)**

Transfers funds between accounts (internal function, called by payout functions).

**Note:** This is called automatically by `ExecuteTier1Payout` and `ExecuteTier2Payout`. You typically don't call this directly.

---

## 🔄 Enhanced Functions

### **ExecuteTier1Payout(claimId)** - Now with Real Transfers!

**What it does:**
1. Validates claim is approved
2. Gets policy to determine insurer and client
3. **Transfers Tier1Amount from insurer account to client account**
4. Creates transaction record on ledger
5. Updates claim status to "paid" only if transfer succeeds

**Account IDs Used:**
- Insurer: `account_<policy.Insurer>` (e.g., `account_AcmeInsurance`)
- Client: `account_<policy.Client>` (e.g., `account_TechCorp`)

**Example:**
```bash
peer chaincode invoke \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["ExecuteTier1Payout","claim:RPT001"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt
```

**What happens:**
- If `Tier1Amount = 30000`:
  - Insurer balance decreases by 30000
  - Client balance increases by 30000
  - Transaction record created with `Purpose: "Tier1Payout"`
  - Claim status updated to "paid"

---

### **ExecuteTier2Payout(claimId)** - Now with Real Transfers!

Same logic as Tier1, but transfers `Tier2Amount`.

---

### **CreatePolicy(...)** - Now Validates Balance!

**New behavior:**
- Checks if insurer account exists
- Validates insurer has sufficient balance to cover `coverageAmount`
- Returns error if insufficient funds

**Note:** Balance validation is optional (warning logged if account doesn't exist).

---

## 📊 Complete Workflow Example

### **Step 1: Create Accounts**

```bash
# Create insurer account with $500,000
peer chaincode invoke \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["CreateAccount","account_AcmeInsurance","InsurerOrgMSP","500000"]}'

# Create client account with $0
peer chaincode invoke \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["CreateAccount","account_TechCorp","ClientOrgMSP","0"]}'
```

### **Step 2: Check Balances**

```bash
# Check insurer balance
peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetBalance","account_AcmeInsurance"]}'
# Expected: 500000.00

# Check client balance
peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetBalance","account_TechCorp"]}'
# Expected: 0.00
```

### **Step 3: Create Policy**

```bash
peer chaincode invoke \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["CreatePolicy","POL001","AcmeInsurance","TechCorp","100000","30000","70000"]}'
```

**Note:** This validates insurer has at least $100,000 balance.

### **Step 4: Submit Claim**

```bash
peer chaincode invoke \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["SubmitClaim","POL001","{\"reportId\":\"RPT001\",\"timestamp\":\"2025-11-06T01:00:00Z\",\"threatType\":\"ransomware\",\"affectedSystems\":[\"server1\"],\"encryptionPercentage\":75.5,\"estimatedImpact\":50000,\"evidenceHashes\":[]}"]}'
```

### **Step 5: Evaluate Tier 1**

```bash
peer chaincode invoke \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["EvaluateTier1Payout","claim:RPT001"]}'
```

### **Step 6: Execute Tier 1 Payout (REAL MONEY TRANSFER!)**

```bash
peer chaincode invoke \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["ExecuteTier1Payout","claim:RPT001"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt
```

**After this:**
- Insurer balance: **470000.00** (was 500000, decreased by 30000)
- Client balance: **30000.00** (was 0, increased by 30000)
- Transaction record created on ledger

### **Step 7: Verify Balances Changed**

```bash
# Check insurer balance (should be 470000)
peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetBalance","account_AcmeInsurance"]}'

# Check client balance (should be 30000)
peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetBalance","account_TechCorp"]}'
```

---

## 🔍 Transaction History

Every transfer creates a transaction record stored as:
- **Key:** `transaction:<txId>`
- **Value:** Transaction JSON object

Transaction records include:
- Transaction ID (from blockchain)
- From/To accounts
- Amount transferred
- Timestamp
- Purpose (Tier1Payout, Tier2Payout, etc.)
- Linked claim ID (if applicable)

---

## ⚠️ Important Notes

### **Account Naming Convention**
- Use pattern: `account_<OrganizationName>`
- Example: `account_AcmeInsurance`, `account_TechCorp`
- This matches the pattern used in `ExecuteTier1Payout` and `ExecuteTier2Payout`

### **Balance Validation**
- `CreatePolicy` checks if insurer has sufficient balance
- If account doesn't exist, policy creation still succeeds (with warning)
- `Transfer` function validates sufficient balance before transfer

### **Atomic Operations**
- Both account balances are updated atomically
- If either update fails, entire transaction is rolled back
- No partial transfers possible

### **Error Handling**
- `Transfer` returns detailed errors if:
  - Account doesn't exist
  - Insufficient balance
  - Amount is negative or zero
  - Transferring to same account

### **Payout Functions**
- `ExecuteTier1Payout` and `ExecuteTier2Payout` will **fail** if:
  - Accounts don't exist
  - Insurer has insufficient balance
  - Transfer fails for any reason
- Claim status is only updated to "paid" if transfer succeeds

---

## 🎯 Key Differences from Before

### **Before (Status Only):**
- `ExecuteTier1Payout` → Updates claim status to "paid"
- No money movement
- No balance tracking

### **After (Real Payments):**
- `ExecuteTier1Payout` → **Transfers money** → Updates claim status
- Actual balance changes
- Transaction records created
- Balance validation on policy creation

---

## 🚀 Quick Start

1. **Create accounts** for insurer and client
2. **Fund insurer account** with sufficient balance
3. **Create policy** (validates balance)
4. **Submit claim** and process as normal
5. **Execute payout** → **Money actually transfers!**
6. **Query balances** to see changes

The payment system is now fully integrated and operational! 🎉

