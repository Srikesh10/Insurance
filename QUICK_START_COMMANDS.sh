#!/bin/bash
# Quick Start Commands for Insurance Network
# Run this script to set up accounts and create a test policy

set -e

echo "=== Insurance Network Quick Start ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PEER_INSURER="docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli"

PEER_CLIENT="docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli"

ORDERER_ARGS="-o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

CHANNEL_ARGS="-C insurance-channel -n insurance"

echo -e "${YELLOW}Step 1: Creating Insurer Account...${NC}"
$PEER_INSURER peer chaincode invoke \
  $ORDERER_ARGS \
  $CHANNEL_ARGS \
  -c '{"function":"CreateAccount","Args":["insurer001","AcmeInsurance","1000000"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt

echo -e "${GREEN}✓ Insurer account created${NC}"
echo "Waiting 10 seconds for transaction to commit..."
sleep 10

echo ""
echo -e "${YELLOW}Step 2: Creating Client Account...${NC}"
$PEER_CLIENT peer chaincode invoke \
  $ORDERER_ARGS \
  $CHANNEL_ARGS \
  -c '{"function":"CreateAccount","Args":["client001","TechCorp","0"]}' \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt

echo -e "${GREEN}✓ Client account created${NC}"
echo "Waiting 10 seconds for transaction to commit..."
sleep 10

echo ""
echo -e "${YELLOW}Step 3: Creating Policy POL001...${NC}"
$PEER_INSURER peer chaincode invoke \
  $ORDERER_ARGS \
  $CHANNEL_ARGS \
  -c '{"function":"CreatePolicy","Args":["POL001","insurer001","client001","100000","30000","70000"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt

echo -e "${GREEN}✓ Policy creation invoked${NC}"
echo -e "${YELLOW}⚠️  Note: Due to endorsement policy issue, transaction may fail validation${NC}"
echo "Waiting 20 seconds for transaction to commit..."
sleep 20

echo ""
echo -e "${YELLOW}Step 4: Querying Policy POL001...${NC}"
$PEER_INSURER peer chaincode query \
  $CHANNEL_ARGS \
  -c '{"function":"GetPolicy","Args":["POL001"]}'

echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "If policy query failed, check POLICY_CREATION_ISSUE.md for details"
echo "The chaincode needs to be redeployed with explicit endorsement policy"

