#!/bin/bash
# Deploy insurance chaincode using Docker CLI container

set -e

CHAINCODE_NAME="insurance"
CHAINCODE_VERSION="1.0"
CHAINCODE_SEQUENCE="1"
CHANNEL_NAME="insurance-channel"
PACKAGE_FILE="${CHAINCODE_NAME}.tar.gz"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Insurance Chaincode Deployment (Docker) ===${NC}"
echo ""

# Check if package exists
if [ ! -f "$PACKAGE_FILE" ]; then
    echo -e "${YELLOW}⚠️  Package not found. Running package.sh first...${NC}"
    ./package.sh
    echo ""
fi

# Copy package to CLI container
echo "📦 Copying package to CLI container..."
docker cp $PACKAGE_FILE cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/$PACKAGE_FILE
echo "   ✓ Copied"
echo ""

# Get package ID first
echo "📋 Calculating Package ID..."
PACKAGE_ID=$(docker exec cli peer lifecycle chaincode calculatepackageid /opt/gopath/src/github.com/hyperledger/fabric/peer/$PACKAGE_FILE)
echo "   Package ID: $PACKAGE_ID"
echo ""

# Install on Insurer peer
echo -e "${BLUE}Step 1: Install on Insurer peer${NC}"
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
    -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
    -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
    cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/$PACKAGE_FILE
echo -e "${GREEN}   ✓ Installed${NC}"
echo ""

# Install on Client peer
echo -e "${BLUE}Step 2: Install on Client peer${NC}"
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
    -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
    -e CORE_PEER_ADDRESS=peer0.client.example.com:8051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
    cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/$PACKAGE_FILE
echo -e "${GREEN}   ✓ Installed${NC}"
echo ""

# Install on Regulator peer
echo -e "${BLUE}Step 3: Install on Regulator peer${NC}"
docker exec -e CORE_PEER_LOCALMSPID=RegulatorOrgMSP \
    -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp \
    -e CORE_PEER_ADDRESS=peer0.regulator.example.com:10051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt \
    cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/$PACKAGE_FILE
echo -e "${GREEN}   ✓ Installed${NC}"
echo ""

# Approve for InsurerOrg
echo -e "${BLUE}Step 4: Approve for InsurerOrg${NC}"
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
    -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
    -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
    -e ORDERER_CA=/opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    cli peer lifecycle chaincode approveformyorg \
    -o orderer.example.com:7050 \
    --channelID $CHANNEL_NAME \
    --name $CHAINCODE_NAME \
    --version $CHAINCODE_VERSION \
    --package-id $PACKAGE_ID \
    --sequence $CHAINCODE_SEQUENCE \
    --tls \
    --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --peerAddresses peer0.insurer.example.com:7051 \
    --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
    --ordererTLSHostnameOverride orderer.example.com
echo -e "${GREEN}   ✓ Approved${NC}"
echo ""

# Approve for ClientOrg
echo -e "${BLUE}Step 5: Approve for ClientOrg${NC}"
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP \
    -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp \
    -e CORE_PEER_ADDRESS=peer0.client.example.com:8051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
    -e ORDERER_CA=/opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    cli peer lifecycle chaincode approveformyorg \
    -o orderer.example.com:7050 \
    --channelID $CHANNEL_NAME \
    --name $CHAINCODE_NAME \
    --version $CHAINCODE_VERSION \
    --package-id $PACKAGE_ID \
    --sequence $CHAINCODE_SEQUENCE \
    --tls \
    --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --peerAddresses peer0.client.example.com:8051 \
    --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
    --ordererTLSHostnameOverride orderer.example.com
echo -e "${GREEN}   ✓ Approved${NC}"
echo ""

# Approve for RegulatorOrg
echo -e "${BLUE}Step 6: Approve for RegulatorOrg${NC}"
docker exec -e CORE_PEER_LOCALMSPID=RegulatorOrgMSP \
    -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp \
    -e CORE_PEER_ADDRESS=peer0.regulator.example.com:10051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt \
    -e ORDERER_CA=/opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    cli peer lifecycle chaincode approveformyorg \
    -o orderer.example.com:7050 \
    --channelID $CHANNEL_NAME \
    --name $CHAINCODE_NAME \
    --version $CHAINCODE_VERSION \
    --package-id $PACKAGE_ID \
    --sequence $CHAINCODE_SEQUENCE \
    --tls \
    --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --peerAddresses peer0.regulator.example.com:10051 \
    --tlsRootCertFiles /opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt \
    --ordererTLSHostnameOverride orderer.example.com
echo -e "${GREEN}   ✓ Approved${NC}"
echo ""

# Commit
echo -e "${BLUE}Step 7: Commit chaincode${NC}"
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
    -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
    -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
    -e ORDERER_CA=/opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    cli peer lifecycle chaincode commit \
    -o orderer.example.com:7050 \
    --channelID $CHANNEL_NAME \
    --name $CHAINCODE_NAME \
    --version $CHAINCODE_VERSION \
    --sequence $CHAINCODE_SEQUENCE \
    --tls \
    --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --ordererTLSHostnameOverride orderer.example.com \
    --peerAddresses peer0.insurer.example.com:7051 \
    --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
    --peerAddresses peer0.client.example.com:8051 \
    --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
    --peerAddresses peer0.regulator.example.com:10051 \
    --tlsRootCertFiles /opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt

echo -e "${GREEN}   ✓ Committed${NC}"
echo ""

echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo ""
echo "Chaincode: $CHAINCODE_NAME"
echo "Version: $CHAINCODE_VERSION"
echo "Channel: $CHANNEL_NAME"
echo "Package ID: $PACKAGE_ID"

