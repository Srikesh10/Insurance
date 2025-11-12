# Critical Issue: Policy Creation Not Working

## Problem
When you create a policy, the invoke command returns **success (status 200)**, but the policy is **not queryable** because the transaction is **marked as INVALID** during validation.

## Root Cause
The chaincode's endorsement policy is set to `/Channel/Application/Endorsement`, which requires organization-level `Endorsement` policies to exist in the channel configuration. These policies **don't exist**, so validation fails with:

```
ENDORSEMENT_POLICY_FAILURE: Only 0 policies were satisfied, but needed 1 of 
[ RegulatorOrg/Endorsement InsurerOrg/Endorsement ClientOrg/Endorsement ]
```

## What's Happening
1. ✅ Invoke command executes successfully on peer
2. ✅ Transaction is sent to orderer
3. ✅ Block is created and distributed
4. ❌ **Transaction is marked INVALID during validation** (endorsement policy failure)
5. ❌ Transaction is NOT committed to ledger
6. ❌ Policy is NOT saved to world state

## Solution

You need to **redeploy the chaincode with an explicit signature-based endorsement policy**.

### Step 1: Package the updated chaincode
```bash
cd /home/reddinho/insurance/chaincode/insurance
docker exec cli peer lifecycle chaincode package /opt/gopath/src/github.com/hyperledger/fabric/peer/insurance.tar.gz \
  --path /opt/gopath/src/github.com/insurance/chaincode/insurance \
  --lang golang \
  --label insurance_1.0
```

### Step 2: Install on all peers
```bash
# Install on Insurer peer
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/insurance.tar.gz

# Install on Client peer
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/insurance.tar.gz

# Install on Regulator peer
docker exec -e CORE_PEER_LOCALMSPID=RegulatorOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.regulator.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/insurance.tar.gz
```

### Step 3: Get Package ID
```bash
PACKAGE_ID=$(docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer lifecycle chaincode queryinstalled --output json 2>&1 | \
  grep -o '"package_id":"[^"]*insurance_1.0[^"]*"' | head -1 | cut -d'"' -f4)

echo "Package ID: $PACKAGE_ID"
```

### Step 4: Approve with Signature Policy
```bash
# Approve for InsurerOrg
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer lifecycle chaincode approveformyorg \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  --channelID insurance-channel \
  --name insurance \
  --version 1.0 \
  --package-id $PACKAGE_ID \
  --sequence 4 \
  --signature-policy "OR('InsurerOrgMSP.peer')"

# Approve for ClientOrg
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer lifecycle chaincode approveformyorg \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  --channelID insurance-channel \
  --name insurance \
  --version 1.0 \
  --package-id $PACKAGE_ID \
  --sequence 4 \
  --signature-policy "OR('ClientOrgMSP.peer')"

# Approve for RegulatorOrg
docker exec -e CORE_PEER_LOCALMSPID=RegulatorOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.regulator.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer lifecycle chaincode approveformyorg \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  --channelID insurance-channel \
  --name insurance \
  --version 1.0 \
  --package-id $PACKAGE_ID \
  --sequence 4 \
  --signature-policy "OR('RegulatorOrgMSP.peer')"
```

### Step 5: Commit with Signature Policy
```bash
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer lifecycle chaincode commit \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C insurance-channel \
  --name insurance \
  --version 1.0 \
  --sequence 4 \
  --signature-policy "OR('InsurerOrgMSP.peer')" \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  --peerAddresses peer0.regulator.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt
```

## After Redeployment

Once the chaincode is redeployed with the correct endorsement policy, transactions will validate successfully and policies will be saved to the ledger.

## Quick Test After Fix

```bash
# Create policy
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

# Wait 15 seconds
sleep 15

# Query policy
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

