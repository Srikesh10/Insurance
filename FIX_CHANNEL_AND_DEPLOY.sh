#!/bin/bash

# Simple script to delete and recreate the channel, then deploy chaincode
# This ensures the channel has the correct LifecycleEndorsement policy

set -e

CHANNEL_NAME="insurance-channel"

echo "=========================================="
echo "FIXING CHANNEL AND DEPLOYING CHAINCODE"
echo "=========================================="
echo ""

# Step 1: Delete existing channel block (if it exists)
echo "🗑️  Removing existing channel block..."
docker exec cli rm -f /opt/config/artifacts/${CHANNEL_NAME}.block 2>/dev/null || true
docker exec cli rm -f /opt/artifacts/${CHANNEL_NAME}.block 2>/dev/null || true
echo "✅ Cleaned up old channel artifacts"
echo ""

# Step 2: Use SETUP_CHANNEL.sh to recreate the channel
echo "📝 Recreating channel with SETUP_CHANNEL.sh..."
bash SETUP_CHANNEL.sh
echo ""

# Step 3: Deploy chaincode
echo "🚀 Deploying chaincode..."
bash chaincode/insurance/deploy-fixed.sh

echo ""
echo "✅✅✅ Done! Channel recreated and chaincode deployed."
