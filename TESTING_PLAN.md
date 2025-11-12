# 🧪 Complete Testing Plan for Insurance Network

## Quick Start Testing (5 minutes)

### Option 1: Automated Script (Easiest)
```bash
cd /home/reddinho/insurance
bash QUICK_START_COMMANDS.sh
```

This will:
- Create accounts
- Create a policy
- Query the policy

**Expected Result:** Policy should be queryable (this confirms the fix is working)

---

## Complete Manual Testing Plan (15-20 minutes)

### Prerequisites Check
```bash
# 1. Check network is running
docker ps | grep -E "peer|orderer|cli"

# 2. If not running, start it
cd /home/reddinho/insurance
docker-compose -f docker-compose/docker-compose.yaml up -d

# 3. Wait 30 seconds for everything to start
sleep 30
```

---

### Test 1: Create Accounts (2 minutes)

**Step 1.1: Create Insurer Account**
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
  -c '{"function":"CreateAccount","Args":["insurer001","AcmeInsurance","1000000"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt
```

**Expected:** `Chaincode invoke successful. result: status:200`

**Step 1.2: Create Client Account**
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
  -c '{"function":"CreateAccount","Args":["client001","TechCorp","0"]}' \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt
```

**Expected:** `Chaincode invoke successful. result: status:200`

**Step 1.3: Wait and Verify Balances**
```bash
# Wait 15 seconds for transactions to commit
sleep 15

# Check insurer balance
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"function":"GetBalance","Args":["insurer001"]}'

# Check client balance
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"function":"GetBalance","Args":["client001"]}'
```

**Expected:** 
- Insurer: `1000000` (or `1e+06`)
- Client: `0`

---

### Test 2: Create Policy (2 minutes)

**Step 2.1: Create Policy**
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
  -c '{"function":"CreatePolicy","Args":["POL001","insurer001","client001","100000","30000","70000"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt
```

**Expected:** `Chaincode invoke successful. result: status:200`

**Step 2.2: Query Policy (CRITICAL TEST)**
```bash
# Wait 15 seconds
sleep 15

docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"function":"GetPolicy","Args":["POL001"]}'
```

**Expected:** JSON with policy details including `"policyId":"POL001"`

**✅ If this works, the endorsement policy fix is confirmed!**

---

### Test 3: Submit Claim (2 minutes)

**Step 3.1: Submit Claim**
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
  -c '{"function":"SubmitClaim","Args":["POL001","{\"reportId\":\"RPT001\",\"threatType\":\"ransomware\",\"affectedSystems\":[\"server1\",\"server2\"],\"encryptionPercentage\":75.5,\"estimatedImpact\":50000,\"evidenceHashes\":[]}"]}' \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt
```

**Expected:** `Chaincode invoke successful. result: status:200 payload:"claim:RPT001"`

**Step 3.2: Query Claim**
```bash
sleep 15

docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"function":"GetClaim","Args":["POL001-RPT001"]}'
```

**Expected:** JSON with claim details

---

### Test 4: Tier 1 Automated Payout (3 minutes)

**Step 4.1: Evaluate Tier 1**
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
  -c '{"function":"EvaluateTier1Payout","Args":["POL001-RPT001"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt
```

**Expected:** `Chaincode invoke successful. result: status:200`

**Step 4.2: Execute Tier 1 Payout (REAL MONEY TRANSFER!)**
```bash
sleep 10

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
  -c '{"function":"ExecuteTier1Payout","Args":["POL001-RPT001"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt
```

**Expected:** `Chaincode invoke successful. result: status:200`

**Step 4.3: Verify Balances Changed**
```bash
sleep 15

# Check insurer balance (should be 970000)
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"function":"GetBalance","Args":["insurer001"]}'

# Check client balance (should be 30000)
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"function":"GetBalance","Args":["client001"]}'
```

**Expected:**
- Insurer: `970000` (was 1000000, paid 30000)
- Client: `30000` (was 0, received 30000)

---

### Test 5: Tier 2 Consensus Payout (5 minutes)

**Step 5.1: Verify for Tier 2 (Insurer)**
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
  -c '{"function":"VerifyForTier2","Args":["POL001-RPT001","InsurerOrgMSP","true"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt
```

**Step 5.2: Verify for Tier 2 (Regulator)**
```bash
sleep 10

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
  -c '{"function":"VerifyForTier2","Args":["POL001-RPT001","RegulatorOrgMSP","true"]}' \
  --peerAddresses peer0.regulator.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt
```

**Step 5.3: Execute Tier 2 Payout**
```bash
sleep 10

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
  -c '{"function":"ExecuteTier2Payout","Args":["POL001-RPT001"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt
```

**Step 5.4: Verify Final Balances**
```bash
sleep 15

# Insurer should be 900000 (paid another 70000)
# Client should be 100000 (received another 70000)
```

---

## 🚀 Quick Test Script (Automated)

For a complete automated test, run:
```bash
cd /home/reddinho/insurance
bash COMPLETE_E2E_TEST.sh
```

This runs all tests automatically and shows pass/fail for each.

---

## 📋 Testing Checklist

- [ ] Network is running
- [ ] Accounts created successfully
- [ ] Balances verified
- [ ] Policy created successfully
- [ ] **Policy is queryable (CRITICAL - confirms fix)**
- [ ] Claim submitted successfully
- [ ] Claim is queryable
- [ ] Tier 1 evaluation works
- [ ] Tier 1 payout executes (money transfers)
- [ ] Balances updated after Tier 1
- [ ] Tier 2 verification works
- [ ] Tier 2 payout executes
- [ ] Final balances correct

---

## ⚠️ Important Notes

1. **Wait Times:** Always wait 10-15 seconds after invoke before querying
2. **Command Format:** Use `{"function":"...","Args":[...]}` format (not just `{"Args":[...]}`)
3. **Single Peer:** Use only ONE peer for invoke to avoid timestamp issues
4. **Error Handling:** If query fails, wait longer and retry

---

## 🎯 Demo Flow Recommendation

For your panel demo, follow this order:

1. **Show network status** (docker ps)
2. **Create accounts** (show balances)
3. **Create policy** (show policy details)
4. **Submit claim** (show claim details)
5. **Evaluate Tier 1** (show automated approval)
6. **Execute Tier 1** (show money transfer, verify balances)
7. **Tier 2 verification** (show consensus process)
8. **Execute Tier 2** (show final balances)

This demonstrates the complete workflow in 10-15 minutes.

---

## 📚 Reference Files

- `PLAY_WITH_NETWORK.md` - Complete command reference
- `QUICK_START_COMMANDS.sh` - Quick setup script
- `COMPLETE_E2E_TEST.sh` - Full automated test suite
- `DEPLOYMENT_AND_TEST_SUCCESS.md` - Deployment confirmation

---

**Good luck with your demo! 🎉**

