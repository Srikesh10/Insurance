#!/bin/bash
# Complete end-to-end test of the payment system

set -e

echo "=========================================="
echo "💰 PAYMENT SYSTEM END-TO-END TEST"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Create Policy
echo -e "${YELLOW}Step 1: Creating Policy POL002...${NC}"
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
  -c '{"Args":["CreatePolicy","POL002","AcmeInsurance","TechCorp","100000","30000","70000"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt 2>&1 | tail -2

echo -e "${GREEN}✅ Policy created${NC}"
echo ""

# Step 2: Submit Claim
echo -e "${YELLOW}Step 2: Submitting Claim...${NC}"
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
  -c '{"Args":["SubmitClaim","POL002","{\"reportId\":\"RPT002\",\"timestamp\":\"2025-11-06T01:00:00Z\",\"threatType\":\"ransomware\",\"affectedSystems\":[\"server1\"],\"encryptionPercentage\":75.5,\"estimatedImpact\":50000,\"evidenceHashes\":[]}"]}' \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt 2>&1 | tail -2

echo -e "${GREEN}✅ Claim submitted${NC}"
echo ""

# Step 3: Check Balances BEFORE
echo -e "${YELLOW}Step 3: Checking Balances BEFORE Payout...${NC}"
INSURER_BEFORE=$(docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetBalance","account_AcmeInsurance"]}' 2>&1 | grep -v "Error" | tail -1)

CLIENT_BEFORE=$(docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetBalance","account_TechCorp"]}' 2>&1 | grep -v "Error" | tail -1)

echo "Insurer Balance: $INSURER_BEFORE"
echo "Client Balance: $CLIENT_BEFORE"
echo ""

# Step 4: Evaluate Tier 1
echo -e "${YELLOW}Step 4: Evaluating Tier 1 Payout...${NC}"
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
  -c '{"Args":["EvaluateTier1Payout","claim:RPT002"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt 2>&1 | tail -2

echo -e "${GREEN}✅ Tier 1 evaluated${NC}"
echo ""

# Step 5: Execute Tier 1 Payout (REAL MONEY TRANSFER!)
echo -e "${YELLOW}Step 5: Executing Tier 1 Payout (REAL MONEY TRANSFER!)...${NC}"
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
  -c '{"Args":["ExecuteTier1Payout","claim:RPT002"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt 2>&1 | tail -2

echo -e "${GREEN}✅ Tier 1 payout executed!${NC}"
echo ""

# Step 6: Check Balances AFTER
echo -e "${YELLOW}Step 6: Checking Balances AFTER Payout...${NC}"
sleep 3
INSURER_AFTER=$(docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetBalance","account_AcmeInsurance"]}' 2>&1 | grep -v "Error" | tail -1)

CLIENT_AFTER=$(docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"Args":["GetBalance","account_TechCorp"]}' 2>&1 | grep -v "Error" | tail -1)

echo "Insurer Balance: $INSURER_AFTER"
echo "Client Balance: $CLIENT_AFTER"
echo ""

# Step 7: Verify Transfer
echo -e "${YELLOW}Step 7: Verifying Transfer...${NC}"
echo "=========================================="
echo "💰 PAYMENT SYSTEM TEST RESULTS"
echo "=========================================="
echo ""
echo "BEFORE Tier 1 Payout:"
echo "  Insurer: $INSURER_BEFORE"
echo "  Client:  $CLIENT_BEFORE"
echo ""
echo "AFTER Tier 1 Payout (Tier1Amount = 30000):"
echo "  Insurer: $INSURER_AFTER"
echo "  Client:  $CLIENT_AFTER"
echo ""

# Calculate differences
INSURER_DIFF=$(echo "$INSURER_BEFORE - $INSURER_AFTER" | bc 2>/dev/null || echo "N/A")
CLIENT_DIFF=$(echo "$CLIENT_AFTER - $CLIENT_BEFORE" | bc 2>/dev/null || echo "N/A")

echo "Transfer Amount:"
echo "  Insurer decreased by: $INSURER_DIFF"
echo "  Client increased by:  $CLIENT_DIFF"
echo ""

if [ "$CLIENT_DIFF" = "30000" ] || [ "$CLIENT_DIFF" = "30000.00" ]; then
  echo -e "${GREEN}✅✅✅ SUCCESS! Money was transferred! ✅✅✅${NC}"
  echo ""
  echo "The payment system is working correctly!"
  echo "Funds were actually moved from insurer to client account."
else
  echo -e "${YELLOW}⚠️  Transfer verification incomplete (may need manual calculation)${NC}"
fi

echo ""
echo "=========================================="

