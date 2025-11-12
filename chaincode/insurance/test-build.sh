#!/bin/bash
# Quick build test script for insurance chaincode

echo "=== Insurance Chaincode Build Test ==="
echo ""

# Check Go version
echo "1. Checking Go version..."
GO_VERSION=$(go version 2>&1)
echo "   $GO_VERSION"

if [[ "$GO_VERSION" == *"go1.18"* ]]; then
    echo "   ⚠️  WARNING: Using Go 1.18 - need 1.21+"
    echo "   Fixing PATH..."
    export PATH=/usr/local/go/bin:$PATH
    GO_VERSION=$(go version 2>&1)
    echo "   Now using: $GO_VERSION"
fi

if [[ "$GO_VERSION" != *"go1.21"* ]] && [[ "$GO_VERSION" != *"go1.22"* ]] && [[ "$GO_VERSION" != *"go1.23"* ]] && [[ "$GO_VERSION" != *"go1.24"* ]] && [[ "$GO_VERSION" != *"go1.25"* ]]; then
    echo "   ❌ ERROR: Need Go 1.21 or higher"
    exit 1
fi

echo "   ✓ Go version OK"
echo ""

# Check we're in the right directory
echo "2. Checking directory..."
CURRENT_DIR=$(pwd)
if [[ "$CURRENT_DIR" != *"chaincode/insurance"* ]]; then
    echo "   ⚠️  Not in chaincode/insurance directory"
    echo "   Current: $CURRENT_DIR"
    echo "   Please run: cd /home/reddinho/insurance/chaincode/insurance"
    exit 1
fi
echo "   ✓ Directory OK: $CURRENT_DIR"
echo ""

# Check go.mod exists
echo "3. Checking go.mod..."
if [ ! -f "go.mod" ]; then
    echo "   ❌ go.mod not found"
    exit 1
fi
echo "   ✓ go.mod exists"
echo ""

# Tidy dependencies
echo "4. Running go mod tidy..."
go mod tidy 2>&1 | grep -v "^go:" || true
if [ $? -ne 0 ]; then
    echo "   ❌ go mod tidy failed"
    exit 1
fi
echo "   ✓ Dependencies OK"
echo ""

# Build
echo "5. Building chaincode..."
go build -v 2>&1 | tail -5
BUILD_EXIT=$?

if [ $BUILD_EXIT -eq 0 ]; then
    echo ""
    echo "   ✓ BUILD SUCCESSFUL!"
    if [ -f "insurance" ]; then
        echo "   Binary: $(ls -lh insurance | awk '{print $5, $9}')"
    fi
else
    echo ""
    echo "   ❌ BUILD FAILED with exit code $BUILD_EXIT"
    exit 1
fi

echo ""
echo "=== All tests passed! ==="

