#!/bin/bash

# Script to completely reset the network by removing all ledger data
# WARNING: This will delete all data in the blockchain!

echo "=========================================="
echo "RESETTING HYPERLEDGER FABRIC NETWORK"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will delete ALL ledger data!"
echo "This includes all accounts, policies, claims, and transactions."
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Stopping network..."
cd docker-compose
docker-compose down

echo ""
echo "Removing ledger data volumes..."
docker volume ls | grep -E "insurance|fabric" | awk '{print $2}' | xargs -r docker volume rm || true

echo ""
echo "Removing chaincode containers and images..."
docker ps -a | grep -E "dev-|insurance" | awk '{print $1}' | xargs -r docker rm -f || true
docker images | grep -E "dev-|insurance" | awk '{print $3}' | xargs -r docker rmi -f || true

echo ""
echo "Cleaning up crypto materials (optional - comment out if you want to keep certs)..."
# Uncomment the next line if you want to regenerate crypto materials
# rm -rf ../crypto-config/*

echo ""
echo "✅ Network reset complete!"
echo ""
echo "To restart the network:"
echo "1. cd docker-compose"
echo "2. docker-compose up -d"
echo "3. Run SETUP_CHANNEL.sh"
echo "4. Run deploy-fixed.sh"

