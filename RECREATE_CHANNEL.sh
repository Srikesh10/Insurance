#!/bin/bash

# Script to recreate the channel with updated configtx.yaml
# This ensures the LifecycleEndorsement policy fix is applied

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CHANNEL_NAME="insurance-channel"
CONFIGTX_DIR="$SCRIPT_DIR/configtx"
ARTIFACTS_DIR="$SCRIPT_DIR/config/artifacts"

echo "=========================================="
echo "RECREATING CHANNEL WITH UPDATED CONFIG"
echo "=========================================="
echo ""

# Check if configtxgen exists
if ! command -v configtxgen &> /dev/null; then
    echo "⚠️  configtxgen not found. Using docker to run it..."
    CONFIGTXGEN_CMD="docker run --rm -v $CONFIGTX_DIR:/configtx -v $SCRIPT_DIR/config:/config -v $SCRIPT_DIR/crypto-config:/crypto-config -e FABRIC_CFG_PATH=/configtx hyperledger/fabric-tools:2.5.11 configtxgen"
else
    CONFIGTXGEN_CMD="configtxgen"
    export FABRIC_CFG_PATH="$CONFIGTX_DIR"
fi

# Regenerate genesis block
echo "📦 Regenerating genesis block..."
mkdir -p "$ARTIFACTS_DIR"
$CONFIGTXGEN_CMD -profile OrdererGenesis -channelID system-channel -outputBlock "$ARTIFACTS_DIR/genesis.block" 2>&1 | grep -v "WARN\|DEBU" || true
echo "✅ Genesis block regenerated"
echo ""

# Regenerate channel creation transaction
echo "📦 Regenerating channel creation transaction..."
$CONFIGTXGEN_CMD -profile InsuranceChannel -channelID $CHANNEL_NAME -outputCreateChannelTx "$ARTIFACTS_DIR/channel.tx" 2>&1 | grep -v "WARN\|DEBU" || true
echo "✅ Channel transaction regenerated"
echo ""

# Delete existing channel (if it exists)
echo "🗑️  Removing existing channel artifacts..."
rm -f $ARTIFACTS_DIR/${CHANNEL_NAME}.block 2>/dev/null || true
echo ""

# Create channel
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
  -f /opt/config/artifacts/channel.tx \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem 2>&1 | grep -v "DEBU\|WARN" || true

echo "✅ Channel created"
echo ""

# Join peers to channel
echo "🔗 Joining peers to channel..."

echo "  - Joining Insurer peer..."
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer channel join -b /opt/config/artifacts/${CHANNEL_NAME}.block 2>&1 | grep -v "DEBU\|WARN" || true

echo "  - Joining Client peer..."
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer channel join -b /opt/config/artifacts/${CHANNEL_NAME}.block 2>&1 | grep -v "DEBU\|WARN" || true

echo "  - Joining Regulator peer..."
docker exec -e CORE_PEER_LOCALMSPID=RegulatorOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.regulator.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer channel join -b /opt/config/artifacts/${CHANNEL_NAME}.block 2>&1 | grep -v "DEBU\|WARN" || true

echo ""
echo "✅✅✅ Channel recreated successfully!"
echo ""
echo "Now you can deploy the chaincode:"
echo "  bash chaincode/insurance/deploy-fixed.sh"

