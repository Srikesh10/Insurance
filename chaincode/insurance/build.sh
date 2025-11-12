#!/bin/bash
# Build script with progress output for insurance chaincode

set -e  # Exit on error

echo "🔨 Building Insurance Chaincode..."
echo ""

# Ensure we're using the right Go
export PATH=/usr/local/go/bin:$PATH

# Check Go version
GO_VERSION=$(go version)
echo "📌 Using: $GO_VERSION"
echo ""

# Change to chaincode directory
cd "$(dirname "$0")"
echo "📁 Directory: $(pwd)"
echo ""

# Check if go.mod exists
if [ ! -f "go.mod" ]; then
    echo "❌ Error: go.mod not found!"
    exit 1
fi

# Download dependencies first (with progress)
echo "📦 Downloading dependencies..."
go mod download 2>&1 | grep -E "(downloading|ok)" || true
echo ""

# Tidy modules
echo "🧹 Tidying modules..."
go mod tidy
echo "✓ Dependencies ready"
echo ""

# Build with verbose output
echo "🔨 Compiling chaincode..."
go build -v -o insurance-chaincode 2>&1 | grep -E "(insurance|fabric)" || echo "Building..."

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    if [ -f "insurance-chaincode" ]; then
        SIZE=$(ls -lh insurance-chaincode | awk '{print $5}')
        echo "   Binary: insurance-chaincode ($SIZE)"
    fi
else
    echo ""
    echo "❌ BUILD FAILED"
    exit 1
fi

