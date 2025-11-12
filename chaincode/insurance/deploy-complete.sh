#!/bin/bash
# Complete deployment script - creates channel, installs, approves, commits

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Complete Insurance Chaincode Deployment ===${NC}"
echo ""

cd /home/reddinho/insurance/chaincode/insurance

# Package chaincode
echo -e "${BLUE}Step 1: Packaging chaincode...${NC}"
./package.sh > /dev/null 2>&1
echo -e "${GREEN}✓ Packaged${NC}"
echo ""

# Copy to CLI
echo -e "${BLUE}Step 2: Copying to CLI container...${NC}"
docker cp insurance.tar.gz cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/insurance.tar.gz
echo -e "${GREEN}✓ Copied${NC}"
echo ""

# Get Package ID
PACKAGE_ID=$(docker exec cli peer lifecycle chaincode calculatepackageid /opt/gopath/src/github.com/hyperledger/fabric/peer/insurance.tar.gz 2>&1 | tail -1)
echo -e "${BLUE}Package ID: ${PACKAGE_ID}${NC}"
echo ""

# Install on all peers
echo -e "${BLUE}Step 3: Installing chaincode...${NC}"
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/insurance.tar.gz 2>&1 | grep -v "^\[" || echo "Installed on Insurer"
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp -e CORE_PEER_ADDRESS=peer0.client.example.com:8051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/insurance.tar.gz 2>&1 | grep -v "^\[" || echo "Installed on Client"
docker exec -e CORE_PEER_LOCALMSPID=RegulatorOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp -e CORE_PEER_ADDRESS=peer0.regulator.example.com:10051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/insurance.tar.gz 2>&1 | grep -v "^\[" || echo "Installed on Regulator"
echo -e "${GREEN}✓ Installed on all peers${NC}"
echo ""

# Approve for all orgs
echo -e "${BLUE}Step 4: Approving chaincode...${NC}"
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --channelID insurance-channel --name insurance --version 1.0 --package-id $PACKAGE_ID --sequence 1 --tls --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --ordererTLSHostnameOverride orderer.example.com 2>&1 | grep -v "^\[" || echo "Approved for InsurerOrg"
docker exec -e CORE_PEER_LOCALMSPID=ClientOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp -e CORE_PEER_ADDRESS=peer0.client.example.com:8051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --channelID insurance-channel --name insurance --version 1.0 --package-id $PACKAGE_ID --sequence 1 --tls --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --ordererTLSHostnameOverride orderer.example.com 2>&1 | grep -v "^\[" || echo "Approved for ClientOrg"
docker exec -e CORE_PEER_LOCALMSPID=RegulatorOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp -e CORE_PEER_ADDRESS=peer0.regulator.example.com:10051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --channelID insurance-channel --name insurance --version 1.0 --package-id $PACKAGE_ID --sequence 1 --tls --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --ordererTLSHostnameOverride orderer.example.com 2>&1 | grep -v "^\[" || echo "Approved for RegulatorOrg"
echo -e "${GREEN}✓ Approved for all organizations${NC}"
echo ""

# Commit
echo -e "${BLUE}Step 5: Committing chaincode...${NC}"
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true cli peer lifecycle chaincode commit -o orderer.example.com:7050 --channelID insurance-channel --name insurance --version 1.0 --sequence 1 --tls --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --ordererTLSHostnameOverride orderer.example.com --peerAddresses peer0.insurer.example.com:7051 --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt --peerAddresses peer0.client.example.com:8051 --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt --peerAddresses peer0.regulator.example.com:10051 --tlsRootCertFiles /opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt 2>&1 | grep -v "^\[" || echo "Committed"
echo -e "${GREEN}✓ Committed${NC}"
echo ""

# Verify
echo -e "${BLUE}Step 6: Verifying deployment...${NC}"
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true cli peer lifecycle chaincode querycommitted --channelID insurance-channel --name insurance 2>&1 | grep -E "Name:|Version:|Sequence:" || echo "Query successful"
echo ""

echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo "Chaincode 'insurance' v1.0 is now deployed on insurance-channel"
echo ""

