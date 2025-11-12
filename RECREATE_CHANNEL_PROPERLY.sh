#!/bin/bash

# Script to properly recreate the channel with updated configtx.yaml
# This runs configtxgen inside the CLI container where crypto-config is available

set -e

CHANNEL_NAME="insurance-channel"

echo "=========================================="
echo "RECREATING CHANNEL WITH UPDATED CONFIG"
echo "=========================================="
echo ""

# Step 1: Generate new channel.tx inside CLI container
echo "📦 Generating new channel transaction with updated configtx.yaml..."
docker exec cli configtxgen -profile InsuranceChannel -channelID $CHANNEL_NAME -outputCreateChannelTx /opt/artifacts/${CHANNEL_NAME}.tx -configPath /opt/configtx 2>&1 | grep -v "WARN\|DEBU" || true
echo "✅ Channel transaction generated"
echo ""

# Step 2: Delete existing channel block
echo "🗑️  Removing existing channel block..."
docker exec cli rm -f /opt/artifacts/${CHANNEL_NAME}.block 2>/dev/null || true
docker exec cli rm -f ${CHANNEL_NAME}.block 2>/dev/null || true
echo "✅ Cleaned up"
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
echo "🔗 Joining peers to channel..."

echo "  - Joining Insurer peer..."
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer channel join -b ${CHANNEL_NAME}.block 2>&1 | grep -v "DEBU\|WARN" || true

echo "  - Joining Client peer..."
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer channel join -b ${CHANNEL_NAME}.block 2>&1 | grep -v "DEBU\|WARN" || true

echo "  - Joining Regulator peer..."
docker exec -e CORE_PEER_LOCALMSPID=RegulatorOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.regulator.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer channel join -b ${CHANNEL_NAME}.block 2>&1 | grep -v "DEBU\|WARN" || true

echo ""
echo "✅✅✅ Channel recreated successfully!"
echo ""
echo "Now deploy the chaincode:"
echo "  bash chaincode/insurance/deploy-fixed.sh"

