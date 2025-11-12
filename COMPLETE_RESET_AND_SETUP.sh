#!/bin/bash

# Complete reset and setup script
# This will reset the network, restart it, recreate the channel, and deploy chaincode

set -e

echo "=========================================="
echo "COMPLETE NETWORK RESET AND SETUP"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will delete ALL data!"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Step 1: Resetting network..."
bash RESET_NETWORK.sh

echo ""
echo "Step 2: Starting network..."
cd docker-compose
docker-compose up -d
cd ..
echo "✅ Network started"
echo ""

echo "Step 3: Waiting for network to be ready..."
sleep 15

echo ""
echo "Step 4: Setting up channel..."
bash SETUP_CHANNEL.sh

echo ""
echo "Step 5: Deploying chaincode..."
bash chaincode/insurance/deploy-fixed.sh

echo ""
echo "✅✅✅ Complete setup finished!"
echo ""
echo "The network is now ready with:"
echo "- Fresh channel with correct LifecycleEndorsement policy"
echo "- Chaincode deployed and committed"

