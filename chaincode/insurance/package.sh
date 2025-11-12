#!/bin/bash
# Package insurance chaincode for Hyperledger Fabric deployment

set -e

CHAINCODE_NAME="insurance"
CHAINCODE_VERSION="1.0"
CHAINCODE_LABEL="${CHAINCODE_NAME}_${CHAINCODE_VERSION}"
PACKAGE_FILE="${CHAINCODE_NAME}.tar.gz"

echo "=== Packaging Insurance Chaincode ==="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📁 Working directory: $(pwd)"
echo ""

# Clean up any previous packaging artifacts
echo "🧹 Cleaning previous packages..."
rm -f *.tar.gz code.tar.gz metadata.json
echo "   ✓ Cleaned"
echo ""

# Create metadata.json (use golang type for docker-based build)
echo "📝 Creating metadata.json..."
cat > metadata.json <<EOF
{
    "type": "golang",
    "label": "${CHAINCODE_LABEL}"
}
EOF
echo "   ✓ Created metadata.json"
echo "   Type: golang"
echo "   Label: ${CHAINCODE_LABEL}"
echo ""

# Create code.tar.gz with source files
echo "📦 Creating code.tar.gz..."
tar -czf code.tar.gz \
    insurance.go \
    go.mod \
    go.sum 2>/dev/null || tar -czf code.tar.gz insurance.go go.mod
echo "   ✓ Created code.tar.gz"
echo "   Contents:"
tar -tzf code.tar.gz | sed 's/^/      - /'
echo ""

# Create final chaincode package
echo "📦 Creating chaincode package..."
tar -czf "${PACKAGE_FILE}" metadata.json code.tar.gz
echo "   ✓ Created ${PACKAGE_FILE}"
echo ""

# Clean up intermediate files
rm -f code.tar.gz metadata.json
echo "🧹 Cleaned intermediate files"
echo ""

# Show package info
echo "=== Package Information ==="
ls -lh "${PACKAGE_FILE}"
echo ""
echo "✅ Chaincode packaged successfully!"
echo ""
echo "Package file: ${PACKAGE_FILE}"
echo "Ready for installation on Hyperledger Fabric peers"
echo ""

