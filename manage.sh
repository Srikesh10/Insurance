#!/bin/bash
# Master Management Script for Insurance Blockchain

function print_help {
    echo "Usage: ./manage.sh [command]"
    echo ""
    echo "Commands:"
    echo "  up      Start the network (Docker Compose)"
    echo "  down    Stop and Teardown the network (removes volumes)"
    echo "  setup   Create channel and join peers"
    echo "  deploy  Deploy/Upgrade the chaincode"
    echo "  test    Run End-to-End Tests"
    echo "  help    Show this help message"
}

if [ "$1" == "up" ]; then
    echo "🚀 Starting Network..."
    docker-compose -f docker-compose/docker-compose.yaml up -d
    echo "✅ Network Started"

elif [ "$1" == "down" ]; then
    echo "🛑 Tearing Down Network..."
    docker-compose -f docker-compose/docker-compose.yaml down -v
    echo "✅ Network Stopped & Cleaned"

elif [ "$1" == "setup" ]; then
    echo "🔧 Setting up Channel..."
    # Ensure we run from root for consistency
    bash network-scripts/setup_channel.sh

elif [ "$1" == "deploy" ]; then
    echo "📦 Deploying Chaincode..."
    cd chaincode/insurance
    bash deploy.sh
    cd ../..

elif [ "$1" == "test" ]; then
    echo "🧪 Running Tests..."
    bash network-scripts/test_e2e.sh

else
    print_help
fi
