#!/bin/bash

# Script to clear/delete test accounts from the ledger
# This uses direct ledger access to remove accounts

CHANNEL_NAME="insurance-channel"
CHAINCODE_NAME="insurance"

echo "=========================================="
echo "CLEARING TEST ACCOUNTS"
echo "=========================================="
echo ""

# Function to delete an account by setting its balance to 0 and removing it
# Since we don't have a DeleteAccount function, we'll need to check what accounts exist first

echo "Checking existing accounts..."
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C $CHANNEL_NAME \
  -n $CHAINCODE_NAME \
  -c '{"function":"GetAllAccounts","Args":[]}' 2>&1 | jq -r '.[].accountId' 2>/dev/null || echo "No accounts found or jq not available"

echo ""
echo "Note: Hyperledger Fabric doesn't support deleting ledger entries."
echo "Accounts are immutable once created. To 'reset' accounts, you would need to:"
echo "1. Stop the network"
echo "2. Remove the ledger data (docker volumes)"
echo "3. Restart the network"
echo ""
echo "Or create new accounts with different IDs."
echo ""
echo "Would you like to see the current accounts? (y/n)"
read -t 5 response || response="n"
if [ "$response" = "y" ]; then
    docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
      -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
      -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
      -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
      -e CORE_PEER_TLS_ENABLED=true \
      cli peer chaincode query \
      -C $CHANNEL_NAME \
      -n $CHAINCODE_NAME \
      -c '{"function":"GetAllAccounts","Args":[]}' 2>&1
fi

