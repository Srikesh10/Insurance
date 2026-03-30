# 🏗️ Insurance Project - Complete Overview

## 📋 Core Concept

This is a **Hyperledger Fabric blockchain network** implementing a **two-tier parametric cyber insurance system** with **real payment functionality**.

### What It Does:
- **Manages insurance policies** for cyber security incidents
- **Processes claims** with automated and consensus-based evaluation
- **Transfers real funds** between accounts when payouts are approved
- **Maintains immutable records** of all policies, claims, and transactions

### Key Innovation:
- **Tier 1**: Automated payouts based on parametric triggers (threat type + encryption percentage > 50%)
- **Tier 2**: Consensus-based payouts requiring multiple organization approvals
- **Real Money**: Actual fund transfers between accounts (not just status tracking)

---

## 🏛️ System Architecture

### Organizations (4 Total)

1. **InsurerOrg** (`InsurerOrgMSP`)
   - Creates insurance policies
   - Evaluates Tier 1 payouts
   - Executes payouts
   - Manages coverage amounts

2. **ClientOrg** (`ClientOrgMSP`)
   - Purchases insurance policies
   - Submits claims when incidents occur
   - Receives payouts

3. **RegulatorOrg** (`RegulatorOrgMSP`)
   - Verifies Tier 2 claims (consensus mechanism)
   - Provides regulatory oversight
   - Approves/denies high-value payouts

4. **SOCOrg** (`SOCOrgMSP`)
   - Monitors security incidents
   - Currently defined but not actively used in main channel

### Network Components

- **Orderer**: `orderer.example.com:7050` - Orders transactions into blocks
- **Peers**: 
  - `peer0.insurer.example.com:7051`
  - `peer0.client.example.com:7051` (mapped to host port 8051)
  - `peer0.regulator.example.com:7051` (mapped to host port 10051)
  - `peer0.soc.example.com:7051` (mapped to host port 9051)
- **Channel**: `insurance-channel` (active, with chaincode deployed)
- **Chaincode**: `insurance` version 1.0
- **Network**: Docker bridge network `insurance-net`

---

## 💻 Chaincode Functions

### Policy Management

1. **`CreatePolicy(policyId, insurer, client, coverageAmount, tier1Amount, tier2Amount)`**
   - Creates a new insurance policy
   - Validates insurer has sufficient balance
   - Stores policy in ledger
   - **Example**: `CreatePolicy("POL001", "AcmeInsurance", "TechCorp", 100000, 30000, 70000)`

2. **`GetPolicy(policyId)`**
   - Retrieves policy details from ledger
   - Returns: PolicyID, Insurer, Client, CoverageAmount, Tier1Amount, Tier2Amount, Status

### Claim Management

3. **`SubmitClaim(policyId, incidentReportJSON)`**
   - Submits a new claim with incident report
   - Links claim to policy
   - Sets Tier1 and Tier2 status to "pending"
   - **Returns**: Claim ID (format: `claim:RPT001`)

4. **`GetClaim(claimId)`**
   - Retrieves claim details from ledger
   - Returns full claim with status, amounts, approvals

### Tier 1 Payout (Automated)

5. **`EvaluateTier1Payout(claimId)`**
   - Checks parametric triggers:
     - Threat type matches policy triggers
     - Encryption percentage > 50%
   - Auto-approves if both conditions met
   - Auto-denies otherwise
   - Updates claim status to "approved" or "denied"

6. **`ExecuteTier1Payout(claimId)`**
   - **Transfers money** from insurer account to client account
   - Updates claim status to "paid"
   - Records transaction on ledger
   - **This is where real money moves!**

### Tier 2 Payout (Consensus-Based)

7. **`VerifyForTier2(claimId, verifierOrg, approval)`**
   - Records verifier organization's approval/denial
   - Requires at least 2 verifiers
   - Majority approval → approved
   - Majority denial → denied

8. **`ExecuteTier2Payout(claimId)`**
   - **Transfers money** from insurer account to client account
   - Updates claim status to "paid"
   - Records transaction on ledger
   - **This is where real money moves!**

### Account Management

9. **`CreateAccount(accountId, owner, initialBalance)`**
   - Creates a new account with initial balance
   - Account ID pattern: `account_<OrganizationName>`
   - **Example**: `CreateAccount("account_AcmeInsurance", "InsurerOrgMSP", 500000)`

10. **`GetAccount(accountId)`**
    - Retrieves account details: ID, Owner, Balance, CreatedAt

11. **`GetBalance(accountId)`**
    - Returns current balance of an account
    - **Example**: `GetBalance("account_AcmeInsurance")` → `500000.00`

12. **`GetAllAccounts()`**
    - Returns list of all accounts in the system

### Transfer Function (Internal)

13. **`Transfer(fromAccountId, toAccountId, amount, purpose, claimId)`**
    - Internal function called by payout functions
    - Atomically transfers funds between accounts
    - Records transaction history
    - Validates sufficient balance before transfer

---

## 🧪 How to Test Everything

### Prerequisites

1. **Check Network Status**
   ```bash
   cd /home/reddinho/insurance
   docker ps
   ```
   Should show: orderer, 4 peers, CLI container, chaincode containers

2. **Start Network (if not running)**
   ```bash
   docker-compose -f docker-compose/docker-compose.yaml up -d
   ```

3. **Check Channel Status**
   ```bash
   docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
     -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
     -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
     -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
     -e CORE_PEER_TLS_ENABLED=true \
     cli peer channel getinfo -c insurance-channel
   ```

---

### Test 1: Complete End-to-End Workflow (Recommended)

**Run the automated test script:**
```bash
cd /home/reddinho/insurance
./TEST_PAYMENT_SYSTEM.sh
```

This script will:
1. Create a policy (POL002)
2. Submit a claim with ransomware incident (75.5% encryption)
3. Check balances BEFORE payout
4. Evaluate Tier 1 (should auto-approve)
5. Execute Tier 1 payout (transfers $30,000)
6. Check balances AFTER payout
7. Verify money was transferred

**Expected Result:**
- Insurer balance decreases by $30,000
- Client balance increases by $30,000
- Transaction recorded on blockchain

---

### Test 2: Interactive Demo Script

**Run the interactive menu:**
```bash
cd /home/reddinho/insurance/chaincode/insurance
./interactive-demo.sh
```

This provides a menu to:
- Create policies
- Query policies
- Submit claims
- Evaluate Tier 1
- Execute Tier 1
- Verify Tier 2
- Query claims
- Run complete demo

---

### Test 3: Manual Step-by-Step Testing

#### Step 1: Create Accounts

```bash
# Create insurer account with $500,000
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode invoke \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["CreateAccount","account_AcmeInsurance","InsurerOrgMSP","500000"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt

# Create client account with $0
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode invoke \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["CreateAccount","account_TechCorp","ClientOrgMSP","0"]}' \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt
```

#### Step 2: Create a Policy

```bash
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode invoke \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["CreatePolicy","POL001","AcmeInsurance","TechCorp","100000","30000","70000"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt
```

#### Step 3: Query the Policy

```bash
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetPolicy","POL001"]}'
```

#### Step 4: Submit a Claim

```bash
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode invoke \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["SubmitClaim","POL001","{\"reportId\":\"RPT001\",\"timestamp\":\"2025-11-06T01:00:00Z\",\"threatType\":\"ransomware\",\"affectedSystems\":[\"server1\",\"server2\"],\"encryptionPercentage\":75.5,\"estimatedImpact\":50000,\"evidenceHashes\":[\"hash1\",\"hash2\"]}"]}' \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt
```

#### Step 5: Evaluate Tier 1 (Auto-Approval)

```bash
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode invoke \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["EvaluateTier1Payout","claim:RPT001"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt
```

**Note**: For Tier 1 to auto-approve, the policy must have `"ransomware"` in its `ParametricTriggers` list. Currently, policies are created with empty triggers. To test auto-approval, you need to either:
- Modify the chaincode to add default triggers, OR
- Create a policy with triggers already set

#### Step 6: Check Balances BEFORE Payout

```bash
# Insurer balance
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetBalance","account_AcmeInsurance"]}'

# Client balance
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetBalance","account_TechCorp"]}'
```

#### Step 7: Execute Tier 1 Payout (Money Transfer!)

```bash
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode invoke \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["ExecuteTier1Payout","claim:RPT001"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt
```

#### Step 8: Check Balances AFTER Payout

Repeat Step 6 commands. You should see:
- Insurer balance decreased by $30,000
- Client balance increased by $30,000

#### Step 9: Query the Claim

```bash
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetClaim","claim:RPT001"]}'
```

Should show `tier1Status: "paid"`

---

### Test 4: Tier 2 Consensus Testing

#### Step 1: Verify for Tier 2 (Insurer Approves)

```bash
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode invoke \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["VerifyForTier2","claim:RPT001","InsurerOrgMSP","true"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt
```

#### Step 2: Verify for Tier 2 (Regulator Approves)

```bash
docker exec -e CORE_PEER_LOCALMSPID=RegulatorOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.regulator.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode invoke \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["VerifyForTier2","claim:RPT001","RegulatorOrgMSP","true"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.regulator.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt
```

#### Step 3: Query Claim (Should show Tier 2 approved)

```bash
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetClaim","claim:RPT001"]}'
```

Should show `tier2Status: "approved"`

#### Step 4: Execute Tier 2 Payout (Money Transfer!)

```bash
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode invoke \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["ExecuteTier2Payout","claim:RPT001"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt
```

#### Step 5: Verify Final Balances

Should see:
- Insurer balance decreased by additional $70,000
- Client balance increased by additional $70,000
- Total payout: $100,000 (Tier1: $30,000 + Tier2: $70,000)

---

## 🔍 Quick Query Commands

### Query Policy
```bash
cd /home/reddinho/insurance
./QUERY_WITH_ECHO.sh
```

Or use the simple query script:
```bash
./run-query.sh
```

### Query Account Balance
```bash
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetBalance","account_AcmeInsurance"]}'
```

### Get All Accounts
```bash
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetAllAccounts"]}'
```

---

## 📊 Data Flow Diagram

```
1. CREATE ACCOUNTS
   ├─ CreateAccount("account_AcmeInsurance", "InsurerOrgMSP", 500000)
   └─ CreateAccount("account_TechCorp", "ClientOrgMSP", 0)

2. CREATE POLICY
   ├─ CreatePolicy("POL001", "AcmeInsurance", "TechCorp", 100000, 30000, 70000)
   └─ Validates insurer has sufficient balance

3. SUBMIT CLAIM
   ├─ SubmitClaim("POL001", incidentReportJSON)
   └─ Creates claim with status: tier1Status="pending", tier2Status="pending"

4. EVALUATE TIER 1
   ├─ EvaluateTier1Payout("claim:RPT001")
   ├─ Checks: threatType matches triggers AND encryptionPercentage > 50%
   └─ Updates: tier1Status="approved" or "denied"

5. EXECUTE TIER 1 PAYOUT
   ├─ ExecuteTier1Payout("claim:RPT001")
   ├─ Transfer("account_AcmeInsurance", "account_TechCorp", 30000, "Tier1Payout", "claim:RPT001")
   ├─ Insurer balance: 500000 → 470000
   ├─ Client balance: 0 → 30000
   └─ Updates: tier1Status="paid"

6. VERIFY TIER 2 (Consensus)
   ├─ VerifyForTier2("claim:RPT001", "InsurerOrgMSP", true)
   ├─ VerifyForTier2("claim:RPT001", "RegulatorOrgMSP", true)
   └─ Updates: tier2Status="approved" (2+ verifiers, majority approved)

7. EXECUTE TIER 2 PAYOUT
   ├─ ExecuteTier2Payout("claim:RPT001")
   ├─ Transfer("account_AcmeInsurance", "account_TechCorp", 70000, "Tier2Payout", "claim:RPT001")
   ├─ Insurer balance: 470000 → 400000
   ├─ Client balance: 30000 → 100000
   └─ Updates: tier2Status="paid"
```

---

## 🎯 Key Testing Scenarios

### Scenario 1: Tier 1 Auto-Approval
- **Setup**: Policy with "ransomware" in triggers, claim with encryptionPercentage > 50%
- **Expected**: Tier 1 auto-approves
- **Result**: Money transfers automatically

### Scenario 2: Tier 1 Auto-Denial
- **Setup**: Policy without matching triggers OR encryptionPercentage ≤ 50%
- **Expected**: Tier 1 auto-denies
- **Result**: No money transfer

### Scenario 3: Tier 2 Consensus Approval
- **Setup**: 2+ organizations approve
- **Expected**: Tier 2 status = "approved"
- **Result**: Can execute payout

### Scenario 4: Tier 2 Consensus Denial
- **Setup**: 2+ organizations, majority deny
- **Expected**: Tier 2 status = "denied"
- **Result**: Cannot execute payout

### Scenario 5: Insufficient Balance
- **Setup**: Insurer account balance < coverage amount
- **Expected**: CreatePolicy fails with error
- **Result**: Policy not created

---

## 📝 Important Notes

1. **Claim ID Format**: `claim:{ReportID}` (e.g., `claim:RPT001`)
2. **Account ID Format**: `account_{OrganizationName}` (e.g., `account_AcmeInsurance`)
3. **Tier 1 Auto-Approval**: Requires policy to have `"ransomware"` in `ParametricTriggers` AND encryptionPercentage > 50%
4. **Tier 2 Consensus**: Requires at least 2 verifiers with majority approval
5. **Money Transfers**: Only happen when `ExecuteTier1Payout` or `ExecuteTier2Payout` is called
6. **Balance Validation**: `CreatePolicy` checks if insurer has sufficient balance

---

## 🚀 Quick Start Summary

1. **Check network**: `docker ps`
2. **Run test**: `./TEST_PAYMENT_SYSTEM.sh`
3. **Or use interactive**: `./chaincode/insurance/interactive-demo.sh`
4. **Query anything**: Use `QUERY_WITH_ECHO.sh` or manual commands above

---

## 📚 Additional Documentation

- `ARCHITECTURE_EXPLANATION.md` - Full architecture details
- `PLAY_WITH_NETWORK.md` - Interactive command guide
- `PROJECT_REVIEW.md` - Project review and status
- `PAYMENT_SYSTEM_COMPLETE.md` - Payment system details
- `TEST_PAYMENT_SYSTEM.sh` - Automated test script
- `chaincode/insurance/README.md` - Chaincode documentation

---

**Last Updated**: Based on project review as of November 2025




