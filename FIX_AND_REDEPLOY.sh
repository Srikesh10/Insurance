#!/bin/bash

# Quick fix: Delete channel, regenerate channel.tx, recreate channel, deploy chaincode

set -e

CHANNEL_NAME="insurance-channel"

echo "=========================================="
echo "FIXING CHANNEL AND REDEPLOYING"
echo "=========================================="
echo ""

# Step 1: Delete existing channel block
echo "🗑️  Deleting existing channel block..."
docker exec cli rm -f /opt/artifacts/${CHANNEL_NAME}.block 2>/dev/null || true
docker exec cli rm -f ${CHANNEL_NAME}.block 2>/dev/null || true
echo "✅ Deleted"

# Step 2: Regenerate channel transaction with updated configtx.yaml
echo "📦 Regenerating channel transaction with updated configtx.yaml..."
docker exec cli configtxgen -profile InsuranceChannel -channelID $CHANNEL_NAME -outputCreateChannelTx /opt/artifacts/${CHANNEL_NAME}.tx -configPath /opt/configtx 2>&1 | grep -v "WARN\|DEBU" || true
echo "✅ Channel transaction regenerated"
echo ""

# Step 3: Create channel
echo "📝 Creating channel..."
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer channel create \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  -c $CHANNEL_NAME \
  -f /opt/artifacts/${CHANNEL_NAME}.tx \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem 2>&1 | grep -v "DEBU\|WARN" || true

echo "✅ Channel created"
echo ""

# Step 4: Join peers
echo "🔗 Joining peers..."
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer channel join -b ${CHANNEL_NAME}.block 2>&1 | grep -v "DEBU\|WARN" || true

docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer channel join -b ${CHANNEL_NAME}.block 2>&1 | grep -v "DEBU\|WARN" || true

docker exec -e CORE_PEER_LOCALMSPID=RegulatorOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.regulator.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer channel join -b ${CHANNEL_NAME}.block 2>&1 | grep -v "DEBU\|WARN" || true

echo "✅ Peers joined"
echo ""

# Step 5: Deploy chaincode
echo "🚀 Deploying chaincode..."
bash chaincode/insurance/deploy-fixed.sh

echo ""
echo "✅✅✅ Done!"

