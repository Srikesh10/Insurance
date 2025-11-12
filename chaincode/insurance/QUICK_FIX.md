# Quick Fix for Hanging Build

If `go build` appears to hang with no output, try these solutions:

## Solution 1: Use the Build Script (Recommended)
```bash
cd /home/reddinho/insurance/chaincode/insurance
./build.sh
```

## Solution 2: Set Network Proxy to Direct (if network is slow)
```bash
cd /home/reddinho/insurance/chaincode/insurance
export GOPROXY=direct
go build -v
```

## Solution 3: Build with Verbose Output
```bash
cd /home/reddinho/insurance/chaincode/insurance
go build -v -o insurance-chaincode
```

## Solution 4: Check if Build Actually Works (it might be silent)
```bash
cd /home/reddinho/insurance/chaincode/insurance
go build -o test-binary
ls -lh test-binary
# If file exists, build succeeded!
```

## Solution 5: Clean and Rebuild
```bash
cd /home/reddinho/insurance/chaincode/insurance
go clean -cache -modcache
go mod download
go build -v
```

## Why It Might Appear to Hang

1. **Go build is silent on success** - No output means it worked!
2. **Network timeout** - Downloading dependencies can take time
3. **Cache issues** - Corrupted cache can cause hangs

## Verify Your Setup

```bash
# Check Go version
export PATH=/usr/local/go/bin:$PATH
go version  # Should show 1.21.6

# Check you're in right directory
pwd  # Should end with chaincode/insurance

# Check go.mod exists
ls go.mod
```

