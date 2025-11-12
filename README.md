# Insurance Blockchain Network

A Hyperledger Fabric blockchain network implementing a two-tier parametric cyber insurance system with real payment functionality.

## Project Structure

```
insurance/
├── chaincode/              # Chaincode source code
│   └── insurance/
│       ├── insurance.go    # Main chaincode implementation
│       ├── go.mod          # Go dependencies
│       └── deploy-fixed.sh # Deployment script
├── config/                 # Network configuration
│   ├── core.yaml          # Peer configuration
│   └── artifacts/         # Generated artifacts (genesis block, etc.)
├── configtx/              # Channel configuration
│   └── configtx.yaml      # Channel and organization definitions
├── crypto-config/         # Cryptographic materials (certificates, keys)
├── docker-compose/        # Docker Compose configuration
│   └── docker-compose.yaml
├── network-scripts/       # Network management scripts
├── PLAY_WITH_NETWORK.md   # User guide and command reference
├── PROJECT_OVERVIEW.md    # Project overview and architecture
├── ARCHITECTURE_EXPLANATION.md # Detailed architecture documentation
├── SETUP_CHANNEL.sh       # Channel setup script
└── COMPLETE_E2E_TEST.sh   # End-to-end test script
```

## Quick Start

1. **Start the network:**
   ```bash
   docker-compose -f docker-compose/docker-compose.yaml up -d
   ```

2. **Create and join channel:**
   ```bash
   bash SETUP_CHANNEL.sh
   ```

3. **Deploy chaincode:**
   ```bash
   cd chaincode/insurance
   bash deploy-fixed.sh
   ```

4. **Use the network:**
   See `PLAY_WITH_NETWORK.md` for detailed commands and examples.

## Key Features

- **Two-Tier Payout System:**
  - Tier 1: Automated parametric payouts
  - Tier 2: Consensus-based payouts with verifier approval

- **Real Payment System:**
  - Account management
  - Balance tracking
  - Fund transfers
  - Transaction history

- **Organizations:**
  - InsurerOrg: Insurance provider
  - ClientOrg: Policy holders
  - RegulatorOrg: Regulatory oversight
  - SOCOrg: Security Operations Center (verifier)

## Documentation

- `PROJECT_OVERVIEW.md` - High-level project overview
- `ARCHITECTURE_EXPLANATION.md` - Detailed architecture
- `PLAY_WITH_NETWORK.md` - Complete command reference and examples

## Testing

Run the comprehensive test suite:
```bash
bash COMPLETE_E2E_TEST.sh
```

