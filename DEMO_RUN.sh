#!/bin/bash

# ============================================
# DEMO SCRIPT - Run Everything from Scratch
# ============================================

set -e

echo "=========================================="
echo "🚀 STARTING INSURANCE BLOCKCHAIN DEMO"
echo "=========================================="
echo ""

# Step 1: Reset and Start Network
echo "📦 STEP 1: Starting Network..."
echo "----------------------------------------"
cd docker-compose
docker-compose down 2>/dev/null || true
docker-compose up -d
cd ..
echo "✅ Network started"
echo ""

# Step 2: Wait for services to be ready
echo "⏳ STEP 2: Waiting for services to initialize..."
sleep 15
echo "✅ Services ready"
echo ""

# Step 3: Setup Channel
echo "📋 STEP 3: Creating Channel and Joining Peers..."
echo "----------------------------------------"
bash SETUP_CHANNEL.sh
echo "✅ Channel setup complete"
echo ""

# Step 4: Deploy Chaincode
echo "📦 STEP 4: Deploying Chaincode..."
echo "----------------------------------------"
bash chaincode/insurance/deploy-fixed.sh
echo "✅ Chaincode deployed"
echo ""

# Step 5: Run Tests
echo "🧪 STEP 5: Running End-to-End Tests..."
echo "----------------------------------------"
bash COMPLETE_E2E_TEST.sh
echo ""

echo "=========================================="
echo "✅ DEMO COMPLETE!"
echo "=========================================="



