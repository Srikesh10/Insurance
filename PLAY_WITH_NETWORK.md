# 🎮 How to Play With Your Hyperledger Fabric Network

A practical guide to interact with your insurance chaincode!

## 📋 Quick Setup

First, make sure your network is running:
```bash
cd /home/reddinho/insurance
docker-compose -f docker-compose/docker-compose.yaml ps
```

If not running, start it:
```bash
docker-compose -f docker-compose/docker-compose.yaml up -d
```

---

## 🚀 Interactive Commands Guide

### **1. Check Network Status**

```bash
# See all running containers
docker ps

# Check chaincode containers
docker ps | grep insurance

# Check peer logs
docker logs peer0.insurer.example.com --tail 20
```

---

### **2. Create an Insurance Policy**

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
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt
```

**What this does:** Creates a policy with:
- Policy ID: POL001
- Insurer: AcmeInsurance
- Client: JPM
- Total Coverage: $100,000
- Tier 1 (Automated): $30,000
- Tier 2 (Consensus): $70,000

---

### **3. Query a Policy**

**Option 1: Use the script (EASIEST - RECOMMENDED)**
```bash
cd /home/reddinho/insurance
./run-query.sh
```

**Option 2: One-line command (copy entire line)**
```bash
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true cli peer chaincode query -C insurance-channel -n insurance -c '{"function":"GetPolicy","Args":["GetPolicy","POL001"]}'
```

**Option 3: Multi-line with backslashes (if Option 2 doesn't work)**
```bash
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

**Expected output:** JSON with policy details

---

### **4. Submit a Cyber Insurance Claim**

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
  -c '{"function":"SubmitClaim","Args":["POL001","{\"reportId\":\"RPT001\",\"threatType\":\"ransomware\",\"affectedSystems\":[\"server1\",\"server2\"],\"encryptionPercentage\":75.5,\"estimatedImpact\":50000,\"evidenceHashes\":[\"hash1\",\"hash2\"]}"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt
```

**What this does:** Submits a ransomware claim with:
- 75.5% encryption (triggers Tier 1 automatic payout!)
- Affected systems: server1, server2
- Estimated impact: $50,000

---

### **5. Evaluate Tier 1 Payout (Automated)**

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
  -c '{"function":"EvaluateTier1Payout","Args":["POL001-RPT001"],"POL001-RPT001"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt
```

**What this does:** Automatically evaluates if Tier 1 payout should be approved
- If `threatType` is "ransomware" AND `encryptionPercentage > 50%` → **APPROVED**
- Otherwise → **DENIED**

---

### **6. Execute Tier 1 Payout**

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
  -c '{"function":"ExecuteTier1Payout","Args":["POL001-RPT001"],"POL001-RPT001"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt
```

**What this does:** Executes the Tier 1 payout ($30,000) if approved

---

### **7. Verify for Tier 2 (Consensus-Based)**

**Step 1: Insurer approves**
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
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt
```

**Step 2: Regulator approves**
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
  -c '{"function":"VerifyForTier2","Args":["POL001-RPT001","RegulatorOrgMSP","true"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.regulator.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt
```

**What this does:** Requires 2+ organizations to approve before Tier 2 can be executed

---

### **8. Execute Tier 2 Payout**

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
  -c '{"function":"ExecuteTier2Payout","Args":["POL001-RPT001"],"POL001-RPT001"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt
```

**What this does:** Executes Tier 2 payout ($70,000) after consensus approval

---

### **9. Query a Claim**

```bash
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"function":"GetClaim","Args":["POL001-RPT001"],"POL001-RPT001"]}'
```

---

## 🎯 Complete Example Workflow

Here's a complete scenario you can run:

```bash
# 1. Create a policy
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode invoke \
  -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C insurance-channel -n insurance \
  -c '{"function":"CreatePolicy","Args":["POL002","insurer001","client001","BigInsurance","StartupCo","50000","15000","35000"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt

# 2. Submit a claim (ransomware with 80% encryption - triggers Tier 1!)
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode invoke \
  -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C insurance-channel -n insurance \
  -c '{"function":"SubmitClaim","Args":["POL001","POL002","{\"reportId\":\"RPT002\",\"threatType\":\"ransomware\",\"affectedSystems\":[\"db-server\",\"web-server\"],\"encryptionPercentage\":80.0,\"estimatedImpact\":45000,\"evidenceHashes\":[\"abc123\",\"def456\"]}"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt

# 3. Evaluate Tier 1 (should auto-approve!)
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode invoke \
  -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C insurance-channel -n insurance \
  -c '{"function":"EvaluateTier1Payout","Args":["POL001-RPT001"],"POL002-RPT002"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt

# 4. Execute Tier 1 payout
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode invoke \
  -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C insurance-channel -n insurance \
  -c '{"function":"ExecuteTier1Payout","Args":["POL001-RPT001"],"POL002-RPT002"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt

# 5. Query the claim to see status
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel -n insurance \
  -c '{"function":"GetClaim","Args":["POL001-RPT001"],"POL002-RPT002"]}'
```

---

## 🔍 Useful Monitoring Commands

```bash
# Watch chaincode container logs
docker logs -f dev-peer0.insurer.example.com-insurance_1.0-* --tail 50

# Check peer logs
docker logs peer0.insurer.example.com --tail 20

# See all chaincode containers
docker ps | grep insurance

# Check channel info
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer channel getinfo -c insurance-channel
```

---

## 💡 Tips & Tricks

1. **Use aliases** - Create shell aliases for common commands (see below)
2. **Test different scenarios:**
   - Create a claim with encryption < 50% (Tier 1 should deny)
   - Create a claim with encryption > 50% (Tier 1 should approve)
   - Test consensus by having one org approve and one deny Tier 2

3. **Chaincode Claim ID format:** `{PolicyID}-{ReportID}`
   - Example: Policy `POL001` + Report `RPT001` = Claim ID `POL001-RPT001`

4. **Tier 1 Auto-Approval Rules:**
   - `threatType` must be `"ransomware"`
   - `encryptionPercentage` must be `> 50.0`
   - Both conditions must be true!

---

## 🚀 Quick Alias Setup (Optional)

Add these to your `~/.bashrc` for easier commands:

```bash
# Insurance Network Aliases
alias ins-policy='docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true cli'

alias ins-query='ins-policy peer chaincode query -C insurance-channel -n insurance'
alias ins-invoke='ins-policy peer chaincode invoke -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C insurance-channel -n insurance --peerAddresses peer0.insurer.example.com:7051 --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt --peerAddresses peer0.client.example.com:7051 --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt'
```

Then you can use:
```bash
ins-query -c '{"function":"GetPolicy","Args":["GetPolicy","POL001"]}'
```

---

## 🎓 What You Can Learn

1. **Blockchain Transactions** - See how transactions are committed to the ledger
2. **Multi-Organization Consensus** - Watch how Tier 2 requires multiple org approvals
3. **Automated Smart Contracts** - See Tier 1 auto-approve based on parameters
4. **Query vs Invoke** - Understand the difference between reading and writing
5. **Peer Endorsement** - See how multiple peers must endorse transactions

---

**Have fun exploring! 🚀**

