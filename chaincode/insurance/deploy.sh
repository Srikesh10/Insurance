#!/bin/bash
# Deploy insurance chaincode to Hyperledger Fabric network

set -e

# Configuration
CHAINCODE_NAME="insurance"
CHAINCODE_VERSION="1.0"
CHAINCODE_SEQUENCE="1"
CHANNEL_NAME="insurance-channel"
PACKAGE_FILE="${CHAINCODE_NAME}.tar.gz"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Insurance Chaincode Deployment ===${NC}"
echo ""

# Check if package exists
if [ ! -f "$PACKAGE_FILE" ]; then
    echo -e "${YELLOW}⚠️  Package not found. Running package.sh first...${NC}"
    ./package.sh
    echo ""
fi

# Check if peer CLI is available
if [ -z "$PEER_BINARY" ]; then
    if [ -f "/home/reddinho/insurance/fabric-samples/bin/peer" ]; then
        PEER_BINARY="/home/reddinho/insurance/fabric-samples/bin/peer"
    elif command -v peer &> /dev/null; then
        PEER_BINARY=$(command -v peer)
    else
        echo -e "${YELLOW}⚠️  Peer binary not found. Please set PEER_BINARY environment variable${NC}"
        echo "   Example: export PEER_BINARY=/path/to/peer"
        exit 1
    fi
fi

echo -e "${GREEN}Using peer binary: $PEER_BINARY${NC}"
echo ""

# Check if network is running
if ! docker ps | grep -q "peer0.insurer.example.com"; then
    echo -e "${YELLOW}⚠️  Fabric network is not running!${NC}"
    echo "   Please start the network first:"
    echo "   cd /home/reddinho/insurance"
    echo "   docker-compose -f docker-compose/docker-compose.yaml up -d"
    exit 1
fi

# Set environment variables (adjust paths as needed)
# Use fabric-samples config if available, otherwise use local config
if [ -f "/home/reddinho/insurance/fabric-samples/config/core.yaml" ]; then
    export FABRIC_CFG_PATH=/home/reddinho/insurance/fabric-samples/config
elif [ -f "/home/reddinho/insurance/config/core.yaml" ]; then
    export FABRIC_CFG_PATH=/home/reddinho/insurance/config
else
    echo -e "${YELLOW}⚠️  core.yaml not found. Creating minimal config...${NC}"
    mkdir -p /home/reddinho/insurance/config
    cp /home/reddinho/insurance/fabric-samples/config/core.yaml /home/reddinho/insurance/config/core.yaml 2>/dev/null || echo "Please ensure core.yaml exists"
    export FABRIC_CFG_PATH=/home/reddinho/insurance/config
fi
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=/home/reddinho/insurance/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export ORDERER_ADDRESS=orderer.example.com:7050

echo -e "${BLUE}Step 1: Install chaincode on Insurer peer${NC}"
export CORE_PEER_LOCALMSPID=InsurerOrgMSP
export CORE_PEER_MSPCONFIGPATH=/home/reddinho/insurance/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/home/reddinho/insurance/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt

echo "   Installing on peer0.insurer.example.com..."
$PEER_BINARY lifecycle chaincode install $PACKAGE_FILE \
    --peerAddresses peer0.insurer.example.com:7051 \
    --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE \
    --connTimeout 30s
INSTALL_OUTPUT=$($PEER_BINARY lifecycle chaincode install $PACKAGE_FILE 2>&1)
PACKAGE_ID=$(echo "$INSTALL_OUTPUT" | grep -oP 'Package ID: \K[^,]+' || $PEER_BINARY lifecycle chaincode calculatepackageid $PACKAGE_FILE)
echo -e "${GREEN}   ✓ Installed. Package ID: $PACKAGE_ID${NC}"
echo ""

echo -e "${BLUE}Step 2: Install chaincode on Client peer${NC}"
export CORE_PEER_LOCALMSPID=ClientOrgMSP
export CORE_PEER_MSPCONFIGPATH=/home/reddinho/insurance/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/home/reddinho/insurance/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt

echo "   Installing on peer0.client.example.com..."
$PEER_BINARY lifecycle chaincode install $PACKAGE_FILE \
    --peerAddresses peer0.client.example.com:8051 \
    --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE
echo -e "${GREEN}   ✓ Installed${NC}"
echo ""

echo -e "${BLUE}Step 3: Install chaincode on Regulator peer${NC}"
export CORE_PEER_LOCALMSPID=RegulatorOrgMSP
export CORE_PEER_MSPCONFIGPATH=/home/reddinho/insurance/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/home/reddinho/insurance/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt

echo "   Installing on peer0.regulator.example.com..."
$PEER_BINARY lifecycle chaincode install $PACKAGE_FILE \
    --peerAddresses peer0.regulator.example.com:10051 \
    --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE
echo -e "${GREEN}   ✓ Installed${NC}"
echo ""

echo -e "${BLUE}Step 4: Approve chaincode for InsurerOrg${NC}"
export CORE_PEER_LOCALMSPID=InsurerOrgMSP
export CORE_PEER_MSPCONFIGPATH=/home/reddinho/insurance/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/home/reddinho/insurance/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt

echo "   Approving for InsurerOrg..."
$PEER_BINARY lifecycle chaincode approveformyorg \
    -o orderer.example.com:7050 \
    --channelID $CHANNEL_NAME \
    --name $CHAINCODE_NAME \
    --version $CHAINCODE_VERSION \
    --package-id $PACKAGE_ID \
    --sequence $CHAINCODE_SEQUENCE \
    --tls \
    --cafile $ORDERER_CA \
    --peerAddresses peer0.insurer.example.com:7051 \
    --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE \
    --ordererTLSHostnameOverride orderer.example.com
echo -e "${GREEN}   ✓ Approved${NC}"
echo ""

echo -e "${BLUE}Step 5: Approve chaincode for ClientOrg${NC}"
export CORE_PEER_LOCALMSPID=ClientOrgMSP
export CORE_PEER_MSPCONFIGPATH=/home/reddinho/insurance/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/home/reddinho/insurance/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt

echo "   Approving for ClientOrg..."
$PEER_BINARY lifecycle chaincode approveformyorg \
    -o orderer.example.com:7050 \
    --channelID $CHANNEL_NAME \
    --name $CHAINCODE_NAME \
    --version $CHAINCODE_VERSION \
    --package-id $PACKAGE_ID \
    --sequence $CHAINCODE_SEQUENCE \
    --tls \
    --cafile $ORDERER_CA \
    --peerAddresses peer0.client.example.com:8051 \
    --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE \
    --ordererTLSHostnameOverride orderer.example.com
echo -e "${GREEN}   ✓ Approved${NC}"
echo ""

echo -e "${BLUE}Step 6: Approve chaincode for RegulatorOrg${NC}"
export CORE_PEER_LOCALMSPID=RegulatorOrgMSP
export CORE_PEER_MSPCONFIGPATH=/home/reddinho/insurance/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/home/reddinho/insurance/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt

echo "   Approving for RegulatorOrg..."
$PEER_BINARY lifecycle chaincode approveformyorg \
    -o orderer.example.com:7050 \
    --channelID $CHANNEL_NAME \
    --name $CHAINCODE_NAME \
    --version $CHAINCODE_VERSION \
    --package-id $PACKAGE_ID \
    --sequence $CHAINCODE_SEQUENCE \
    --tls \
    --cafile $ORDERER_CA \
    --peerAddresses peer0.regulator.example.com:10051 \
    --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE \
    --ordererTLSHostnameOverride orderer.example.com
echo -e "${GREEN}   ✓ Approved${NC}"
echo ""

echo -e "${BLUE}Step 7: Commit chaincode to channel${NC}"
export CORE_PEER_LOCALMSPID=InsurerOrgMSP
export CORE_PEER_MSPCONFIGPATH=/home/reddinho/insurance/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/home/reddinho/insurance/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt

CLIENT_TLS_ROOTCERT=/home/reddinho/insurance/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt
REGULATOR_TLS_ROOTCERT=/home/reddinho/insurance/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt

echo "   Committing to $CHANNEL_NAME..."
$PEER_BINARY lifecycle chaincode commit \
    -o orderer.example.com:7050 \
    --channelID $CHANNEL_NAME \
    --name $CHAINCODE_NAME \
    --version $CHAINCODE_VERSION \
    --sequence $CHAINCODE_SEQUENCE \
    --tls \
    --cafile $ORDERER_CA \
    --ordererTLSHostnameOverride orderer.example.com \
    --peerAddresses peer0.insurer.example.com:7051 \
    --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE \
    --peerAddresses peer0.client.example.com:8051 \
    --tlsRootCertFiles $CLIENT_TLS_ROOTCERT \
    --peerAddresses peer0.regulator.example.com:10051 \
    --tlsRootCertFiles $REGULATOR_TLS_ROOTCERT

echo -e "${GREEN}   ✓ Committed${NC}"
echo ""

echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo ""
echo "Chaincode: $CHAINCODE_NAME"
echo "Version: $CHAINCODE_VERSION"
echo "Channel: $CHANNEL_NAME"
echo "Package ID: $PACKAGE_ID"
echo ""
echo "You can now invoke chaincode functions on the $CHANNEL_NAME channel."

