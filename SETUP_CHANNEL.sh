#!/bin/bash
# Quick setup script to recreate the channel and test queries

set -e

echo "=== Setting up insurance-channel ==="

# Common env vars
INSURER_ENV="-e CORE_PEER_LOCALMSPID=InsurerOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true"

CLIENT_ENV="-e CORE_PEER_LOCALMSPID=ClientOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true"

REGULATOR_ENV="-e CORE_PEER_LOCALMSPID=RegulatorOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp -e CORE_PEER_ADDRESS=peer0.regulator.example.com:7051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true"

SOC_ENV="-e CORE_PEER_LOCALMSPID=SOCOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/soc.example.com/users/Admin@soc.example.com/msp -e CORE_PEER_ADDRESS=peer0.soc.example.com:7051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/soc.example.com/peers/peer0.soc.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true"

ORDERER_OPTS="-o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

PEER_OPTS="--peerAddresses peer0.insurer.example.com:7051 --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt --peerAddresses peer0.client.example.com:7051 --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt"

CHANNEL="-C insurance-channel"
CHAINCODE="-n insurance"

echo "Step 1: Checking if network is running..."
docker ps | grep -E "peer|orderer|cli" || { echo "❌ Network not running! Start with: docker-compose -f docker-compose/docker-compose.yaml up -d"; exit 1; }

echo "Step 2: Waiting for orderer to be ready..."
sleep 10

echo "Step 2.5: Regenerating channel transaction with updated configtx.yaml..."
docker exec cli configtxgen -profile InsuranceChannel -channelID insurance-channel -outputCreateChannelTx /opt/artifacts/insurance-channel.tx -configPath /opt/configtx 2>&1 | grep -v "WARN\|DEBU" || true
echo "✅ Channel transaction regenerated"

echo "Step 3: Creating channel..."
docker exec $INSURER_ENV cli peer channel create \
    $ORDERER_OPTS \
    -c insurance-channel \
    -f /opt/artifacts/insurance-channel.tx \
    2>&1 | tee /tmp/channel_create.log

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "⚠️  Channel creation failed. Checking orderer logs..."
    docker logs orderer.example.com --tail 20
    exit 1
fi

echo "Step 4: Joining peers to channel..."
docker exec $INSURER_ENV cli peer channel join -b insurance-channel.block 2>&1
docker exec $CLIENT_ENV cli peer channel join -b insurance-channel.block 2>&1  
docker exec $REGULATOR_ENV cli peer channel join -b insurance-channel.block 2>&1
docker exec $SOC_ENV cli peer channel join -b insurance-channel.block 2>&1

echo "Step 5: Verifying channel..."
docker exec $INSURER_ENV cli peer channel list

echo "Step 6: Checking chaincode status..."
docker exec $INSURER_ENV cli peer lifecycle chaincode querycommitted --channelID insurance-channel --name insurance 2>&1 || echo "⚠️  Chaincode not committed yet. Run deploy script first."

echo ""
echo "✅ Channel setup complete!"
echo ""
echo "Now you can test with:"
echo "docker exec $INSURER_ENV cli peer chaincode query $CHANNEL $CHAINCODE -c '{\"Args\":[\"GetPolicy\",\"POL001\"]}'"

