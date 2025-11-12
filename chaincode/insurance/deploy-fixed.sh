#!/bin/bash
# Fixed deployment script that packages chaincode correctly inside CLI container

set -e

CHAINCODE_NAME="insurance"
CHAINCODE_VERSION="1.0"
CHANNEL_NAME="insurance-channel"

echo "=== Deploying Insurance Chaincode ==="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy source files to CLI container
echo "📦 Copying chaincode files to CLI container..."
docker exec cli mkdir -p /opt/gopath/src/github.com/insurance/chaincode/insurance
docker cp "$SCRIPT_DIR/insurance.go" cli:/opt/gopath/src/github.com/insurance/chaincode/insurance/
docker cp "$SCRIPT_DIR/go.mod" cli:/opt/gopath/src/github.com/insurance/chaincode/insurance/
docker cp "$SCRIPT_DIR/go.sum" cli:/opt/gopath/src/github.com/insurance/chaincode/insurance/
echo "✅ Files copied"
echo ""

# Package chaincode using peer command (inside CLI container)
echo "📦 Packaging chaincode..."
docker exec cli peer lifecycle chaincode package /opt/gopath/src/github.com/hyperledger/fabric/peer/insurance.tar.gz \
    --path /opt/gopath/src/github.com/insurance/chaincode/insurance \
    --lang golang \
    --label insurance_1.0 2>&1 | grep -v "go:" || true
echo "✅ Package created"
echo ""

# Install on Insurer peer
echo "📥 Installing on Insurer peer..."
INSTALL_OUTPUT=$(docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/insurance.tar.gz 2>&1)

PACKAGE_ID=$(echo "$INSTALL_OUTPUT" | grep -i "package id" | sed -n 's/.*Package ID: \(.*\), Label.*/\1/p' | head -1)

# If still empty, try alternative format
if [ -z "$PACKAGE_ID" ]; then
  PACKAGE_ID=$(echo "$INSTALL_OUTPUT" | grep -oP 'Package ID: \K[^,]+' | head -1)
fi

# If still empty, query installed packages
if [ -z "$PACKAGE_ID" ]; then
  PACKAGE_ID=$(docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
    -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
    -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
    -e CORE_PEER_TLS_ENABLED=true \
    cli peer lifecycle chaincode queryinstalled 2>&1 | grep "Package ID" | tail -1 | sed -n 's/.*Package ID: \(.*\), Label.*/\1/p')
fi

echo "Package ID: $PACKAGE_ID"
echo "$INSTALL_OUTPUT" | grep -i "package id\|installed\|error" || true
echo ""

# Install on Client peer
echo "📥 Installing on Client peer..."
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/insurance.tar.gz 2>&1 | grep -i "package id\|installed" || true
echo ""

# Install on Regulator peer
echo "📥 Installing on Regulator peer..."
docker exec -e CORE_PEER_LOCALMSPID=RegulatorOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.regulator.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/insurance.tar.gz 2>&1 | grep -i "package id\|installed" || true
echo ""

# Install on SOC peer
echo "📥 Installing on SOC peer..."
docker exec -e CORE_PEER_LOCALMSPID=SOCOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/soc.example.com/users/Admin@soc.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.soc.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/soc.example.com/peers/peer0.soc.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/insurance.tar.gz 2>&1 | grep -i "package id\|installed" || true
echo ""

# Approve for all orgs
echo "✅ Approving for InsurerOrg..."
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
  --package-id "$PACKAGE_ID" \
  --sequence 1 \
  --signature-policy "OR('InsurerOrgMSP.peer', 'ClientOrgMSP.peer', 'RegulatorOrgMSP.peer', 'SOCOrgMSP.peer')" 2>&1 | tail -2

echo "✅ Approving for ClientOrg..."
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
  --package-id "$PACKAGE_ID" \
  --sequence 1 \
  --signature-policy "OR('InsurerOrgMSP.peer', 'ClientOrgMSP.peer', 'RegulatorOrgMSP.peer', 'SOCOrgMSP.peer')" 2>&1 | tail -2

echo "✅ Approving for RegulatorOrg..."
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
  --package-id "$PACKAGE_ID" \
  --sequence 1 \
  --signature-policy "OR('InsurerOrgMSP.peer', 'ClientOrgMSP.peer', 'RegulatorOrgMSP.peer', 'SOCOrgMSP.peer')" 2>&1 | tail -2

echo "✅ Approving for SOCOrg..."
docker exec -e CORE_PEER_LOCALMSPID=SOCOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/soc.example.com/users/Admin@soc.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.soc.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/soc.example.com/peers/peer0.soc.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer lifecycle chaincode approveformyorg \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  --channelID insurance-channel \
  --name insurance \
  --version 1.0 \
  --package-id "$PACKAGE_ID" \
  --sequence 1 \
  --signature-policy "OR('InsurerOrgMSP.peer', 'ClientOrgMSP.peer', 'RegulatorOrgMSP.peer', 'SOCOrgMSP.peer')" 2>&1 | tail -2

echo ""

# Commit
echo "🚀 Committing chaincode..."
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer lifecycle chaincode commit \
  -o orderer.example.com:7050 \
  --channelID insurance-channel \
  --name insurance \
  --version 1.0 \
  --sequence 1 \
  --signature-policy "OR('InsurerOrgMSP.peer', 'ClientOrgMSP.peer', 'RegulatorOrgMSP.peer', 'SOCOrgMSP.peer')" \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  --ordererTLSHostnameOverride orderer.example.com \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  --peerAddresses peer0.client.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
  --peerAddresses peer0.regulator.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt \
  --peerAddresses peer0.soc.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/soc.example.com/peers/peer0.soc.example.com/tls/ca.crt 2>&1

echo ""
echo "✅✅✅ Chaincode deployment complete!"
echo ""
echo "You can now use the chaincode commands from PLAY_WITH_NETWORK.md"

