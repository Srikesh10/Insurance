# Insurance Chaincode

Parametric Cyber Insurance Chaincode for Hyperledger Fabric

## Overview

This chaincode implements a two-tier parametric insurance system:
- **Tier 1**: Automated payouts based on parametric triggers (threat type + encryption percentage > 50%)
- **Tier 2**: Consensus-based payouts requiring multiple verifier approvals

## Prerequisites

- Go 1.21 or higher
- Hyperledger Fabric 2.5.11
- Fabric network running with insurance-channel

## Build

```bash
cd /home/reddinho/insurance/chaincode/insurance
go build
```

## Package

```bash
./package.sh
```

This creates `insurance.tar.gz` ready for deployment.

## Deploy

Make sure your Fabric network is running, then:

```bash
./deploy.sh
```

The deployment script will:
1. Install chaincode on all peers (Insurer, Client, Regulator)
2. Approve chaincode for each organization
3. Commit chaincode to the insurance-channel

## Chaincode Functions

### Policy Management
- `CreatePolicy(policyId, insurer, client, coverageAmount, tier1Amount, tier2Amount)` - Create a new insurance policy

### Claims
- `SubmitClaim(policyId, incidentReportJSON)` - Submit a claim with incident report
- `GetClaim(claimId)` - Retrieve a claim
- `GetPolicy(policyId)` - Retrieve a policy

### Tier 1 (Automated)
- `EvaluateTier1Payout(claimId)` - Evaluate and approve/deny Tier 1 payout based on parametric triggers
- `ExecuteTier1Payout(claimId)` - Execute Tier 1 payout after approval

### Tier 2 (Consensus-based)
- `VerifyForTier2(claimId, verifierOrg, approval)` - Record verifier approval/denial
- `ExecuteTier2Payout(claimId)` - Execute Tier 2 payout after consensus approval

## Testing

After deployment, you can test the chaincode using peer CLI commands:

```bash
# Create a policy
peer chaincode invoke -C insurance-channel -n insurance -c '{"Args":["CreatePolicy","POL001","insurer1","client1","100000","30000","70000"]}'

# Submit a claim
peer chaincode invoke -C insurance-channel -n insurance -c '{"Args":["SubmitClaim","POL001","{\"reportId\":\"RPT001\",\"threatType\":\"ransomware\",\"encryptionPercentage\":75.5}"]}'

# Query a policy
peer chaincode query -C insurance-channel -n insurance -c '{"Args":["GetPolicy","POL001"]}'
```

## Files

- `insurance.go` - Main chaincode implementation
- `go.mod` - Go module dependencies
- `package.sh` - Script to package chaincode
- `deploy.sh` - Script to deploy chaincode
- `build.sh` - Build script with progress output
- `test-build.sh` - Comprehensive build test script

## Network Configuration

The chaincode is configured for:
- **Channel**: insurance-channel
- **Organizations**: InsurerOrg, ClientOrg, RegulatorOrg
- **Peers**: 
  - peer0.insurer.example.com:7051
  - peer0.client.example.com:8051
  - peer0.regulator.example.com:10051

