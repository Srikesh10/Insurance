#!/bin/bash

# Script to completely reset the orderer (delete all channels)

set -e

echo "=========================================="
echo "COMPLETE ORDERER RESET"
echo "=========================================="
echo ""
echo "⚠️  This will delete ALL channels from the orderer!"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Stopping orderer..."
cd docker-compose
docker-compose stop orderer.example.com

echo ""
echo "Deleting orderer's ledger data..."
docker exec orderer.example.com rm -rf /var/hyperledger/production/orderer/chains/* 2>/dev/null || true
docker exec orderer.example.com rm -rf /var/hyperledger/production/orderer/* 2>/dev/null || true

# Also try to remove from host if it's a bind mount
rm -rf /var/hyperledger/production/orderer/chains/* 2>/dev/null || true

echo ""
echo "Restarting orderer..."
docker-compose start orderer.example.com
cd ..

echo ""
echo "Waiting for orderer to be ready..."
sleep 10

echo ""
echo "✅ Orderer reset complete!"
echo ""
echo "Now you can recreate the channel:"
echo "  bash SETUP_CHANNEL.sh"

