# Policy Creation Issue - Root Cause and Solution

## Problem
Policy creation invoke succeeds (status 200) but policy is not queryable. Transaction is being marked as **INVALID** during validation.

## Root Cause
The chaincode's endorsement policy is set to `/Channel/Application/Endorsement` (which is "ANY Endorsement"). This policy requires organization-level `Endorsement` policies to exist in the channel config, but they don't exist. When the transaction is validated, it fails with:

```
ENDORSEMENT_POLICY_FAILURE: Only 0 policies were satisfied, but needed 1 of [ RegulatorOrg/Endorsement InsurerOrg/Endorsement ClientOrg/Endorsement ]
```

## Solutions

### Option 1: Set Chaincode Endorsement Policy (Recommended)
When committing the chaincode, set an explicit signature-based endorsement policy:

```bash
--signature-policy "OR('InsurerOrgMSP.peer')"
```

This allows any peer from InsurerOrg to endorse transactions.

### Option 2: Add Organization-Level Endorsement Policies to Channel
Update the channel configuration to add `Endorsement` policies to each organization. This is complex and requires channel config update.

## Current Status
- Chaincode code is fixed (account ID mismatch resolved)
- Chaincode needs to be redeployed with explicit endorsement policy
- Commands need to use `{"function":"...","Args":[...]}` format

## Quick Fix for Demo

For your demo, you can work around this by:
1. Using the correct command format: `{"function":"CreatePolicy","Args":[...]}`
2. Understanding that transactions may fail validation until the chaincode is redeployed with correct endorsement policy
3. The invoke will return success, but the transaction won't be committed to the ledger

## Files Updated
- `chaincode/insurance/insurance.go` - Fixed account ID mismatch
- `DEMO_GUIDE.md` - Working commands with correct format
- `WORKING_COMMANDS.md` - Step-by-step guide

