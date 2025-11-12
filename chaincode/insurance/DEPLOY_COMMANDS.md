# Chaincode Deployment Commands

## Step-by-Step Deployment Guide

### Step 1: Verify Network is Running
```bash
cd /home/reddinho/insurance/chaincode/insurance
./check-network.sh
```

### Step 2: Verify Chaincode is Packaged
```bash
cd /home/reddinho/insurance/chaincode/insurance
ls -lh insurance.tar.gz
```

If package doesn't exist, create it:
```bash
./package.sh
```

### Step 3: Deploy Chaincode
```bash
cd /home/reddinho/insurance/chaincode/insurance
./deploy.sh
```

---

## Alternative: Manual Deployment Commands

If you prefer to run commands manually, here are the steps:

### Prerequisites
```bash
# Set environment variables
export PATH=/usr/local/go/bin:$PATH
export FABRIC_CFG_PATH=/home/reddinho/insurance/fabric-samples/config
export PEER_BINARY=/home/reddinho/insurance/fabric-samples/bin/peer
export ORDERER_CA=/home/reddinho/insurance/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export ORDERER_ADDRESS=orderer.example.com:7050
export CHAINCODE_NAME=insurance
export CHAINCODE_VERSION=1.0
export CHAINCODE_SEQUENCE=1
export CHANNEL_NAME=insurance-channel
```

### 1. Install on Insurer Peer
```bash
export CORE_PEER_LOCALMSPID=InsurerOrgMSP
export CORE_PEER_MSPCONFIGPATH=/home/reddinho/insurance/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp
export CORE_PEER_ADDRESS=peer0.insurer.example.com:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/home/reddinho/insurance/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt

$PEER_BINARY lifecycle chaincode install insurance.tar.gz
```

### 2. Get Package ID
```bash
export PACKAGE_ID=$($PEER_BINARY lifecycle chaincode calculatepackageid insurance.tar.gz)
echo $PACKAGE_ID
```

### 3. Install on Client Peer
```bash
export CORE_PEER_LOCALMSPID=ClientOrgMSP
export CORE_PEER_MSPCONFIGPATH=/home/reddinho/insurance/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp
export CORE_PEER_ADDRESS=peer0.client.example.com:8051
export CORE_PEER_TLS_ROOTCERT_FILE=/home/reddinho/insurance/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt

$PEER_BINARY lifecycle chaincode install insurance.tar.gz
```

### 4. Install on Regulator Peer
```bash
export CORE_PEER_LOCALMSPID=RegulatorOrgMSP
export CORE_PEER_MSPCONFIGPATH=/home/reddinho/insurance/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp
export CORE_PEER_ADDRESS=peer0.regulator.example.com:10051
export CORE_PEER_TLS_ROOTCERT_FILE=/home/reddinho/insurance/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt

$PEER_BINARY lifecycle chaincode install insurance.tar.gz
```

### 5. Approve for InsurerOrg
```bash
export CORE_PEER_LOCALMSPID=InsurerOrgMSP
export CORE_PEER_MSPCONFIGPATH=/home/reddinho/insurance/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp
export CORE_PEER_ADDRESS=peer0.insurer.example.com:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/home/reddinho/insurance/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt

$PEER_BINARY lifecycle chaincode approveformyorg \
    -o $ORDERER_ADDRESS \
    --channelID $CHANNEL_NAME \
    --name $CHAINCODE_NAME \
    --version $CHAINCODE_VERSION \
    --package-id $PACKAGE_ID \
    --sequence $CHAINCODE_SEQUENCE \
    --tls \
    --cafile $ORDERER_CA
```

### 6. Approve for ClientOrg
```bash
export CORE_PEER_LOCALMSPID=ClientOrgMSP
export CORE_PEER_MSPCONFIGPATH=/home/reddinho/insurance/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp
export CORE_PEER_ADDRESS=peer0.client.example.com:8051
export CORE_PEER_TLS_ROOTCERT_FILE=/home/reddinho/insurance/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt

$PEER_BINARY lifecycle chaincode approveformyorg \
    -o $ORDERER_ADDRESS \
    --channelID $CHANNEL_NAME \
    --name $CHAINCODE_NAME \
    --version $CHAINCODE_VERSION \
    --package-id $PACKAGE_ID \
    --sequence $CHAINCODE_SEQUENCE \
    --tls \
    --cafile $ORDERER_CA
```

### 7. Approve for RegulatorOrg
```bash
export CORE_PEER_LOCALMSPID=RegulatorOrgMSP
export CORE_PEER_MSPCONFIGPATH=/home/reddinho/insurance/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp
export CORE_PEER_ADDRESS=peer0.regulator.example.com:10051
export CORE_PEER_TLS_ROOTCERT_FILE=/home/reddinho/insurance/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt

$PEER_BINARY lifecycle chaincode approveformyorg \
    -o $ORDERER_ADDRESS \
    --channelID $CHANNEL_NAME \
    --name $CHAINCODE_NAME \
    --version $CHAINCODE_VERSION \
    --package-id $PACKAGE_ID \
    --sequence $CHAINCODE_SEQUENCE \
    --tls \
    --cafile $ORDERER_CA
```

### 8. Commit Chaincode
```bash
export CORE_PEER_LOCALMSPID=InsurerOrgMSP
export CORE_PEER_MSPCONFIGPATH=/home/reddinho/insurance/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp
export CORE_PEER_ADDRESS=peer0.insurer.example.com:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/home/reddinho/insurance/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt

$PEER_BINARY lifecycle chaincode commit \
    -o $ORDERER_ADDRESS \
    --channelID $CHANNEL_NAME \
    --name $CHAINCODE_NAME \
    --version $CHAINCODE_VERSION \
    --sequence $CHAINCODE_SEQUENCE \
    --tls \
    --cafile $ORDERER_CA \
    --peerAddresses peer0.insurer.example.com:7051 \
    --tlsRootCertFiles /home/reddinho/insurance/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
    --peerAddresses peer0.client.example.com:8051 \
    --tlsRootCertFiles /home/reddinho/insurance/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt \
    --peerAddresses peer0.regulator.example.com:10051 \
    --tlsRootCertFiles /home/reddinho/insurance/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt
```

### 9. Verify Deployment
```bash
$PEER_BINARY lifecycle chaincode querycommitted \
    --channelID $CHANNEL_NAME \
    --name $CHAINCODE_NAME \
    --tls \
    --cafile $ORDERER_CA
```

---

## Quick Test After Deployment

### Query Chaincode Metadata
```bash
export CORE_PEER_LOCALMSPID=InsurerOrgMSP
export CORE_PEER_MSPCONFIGPATH=/home/reddinho/insurance/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp
export CORE_PEER_ADDRESS=peer0.insurer.example.com:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/home/reddinho/insurance/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt

$PEER_BINARY chaincode query \
    -C $CHANNEL_NAME \
    -n $CHAINCODE_NAME \
    -c '{"Args":["org.hyperledger.fabric:GetMetadata"]}'
```

---

## Troubleshooting

If you get errors:
1. Check network is running: `./check-network.sh`
2. Check channel exists (if not, create it first)
3. Verify package ID matches across all approvals
4. Check logs: `docker logs peer0.insurer.example.com`

