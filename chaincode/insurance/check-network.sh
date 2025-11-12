#!/bin/bash
# Check if Fabric network is running and ready

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Checking Fabric Network Status ==="
echo ""

# Check if Docker is running
if ! docker ps &>/dev/null; then
    echo -e "${RED}✗ Docker is not running${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is running${NC}"

# Check for orderer
if docker ps | grep -q "orderer.example.com"; then
    echo -e "${GREEN}✓ Orderer is running${NC}"
else
    echo -e "${RED}✗ Orderer is not running${NC}"
    ORDERER_DOWN=true
fi

# Check for peers
PEERS=("peer0.insurer.example.com" "peer0.client.example.com" "peer0.regulator.example.com" "peer0.soc.example.com")
ALL_PEERS_UP=true

for peer in "${PEERS[@]}"; do
    if docker ps | grep -q "$peer"; then
        echo -e "${GREEN}✓ $peer is running${NC}"
    else
        echo -e "${RED}✗ $peer is not running${NC}"
        ALL_PEERS_UP=false
    fi
done

echo ""

if [ "$ORDERER_DOWN" = true ] || [ "$ALL_PEERS_UP" = false ]; then
    echo -e "${YELLOW}⚠️  Network is not fully running${NC}"
    echo ""
    echo "To start the network:"
    echo "  cd /home/reddinho/insurance"
    echo "  docker-compose -f docker-compose/docker-compose.yaml up -d"
    echo ""
    echo "To check logs:"
    echo "  docker-compose -f docker-compose/docker-compose.yaml logs -f"
    exit 1
else
    echo -e "${GREEN}✓ All network components are running${NC}"
    echo ""
    echo "Network is ready for chaincode deployment!"
    exit 0
fi

