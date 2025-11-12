# Demo Guide - Quick Reference

## The Issue You Encountered

You tried to create a policy but it wasn't queryable. This is because:

1. **Wrong command format**: You used `{"Args":[...]}` but should use `{"function":"CreatePolicy","Args":[...]}`
2. **Account ID mismatch**: The chaincode was looking for accounts with `account_` prefix but accounts are stored with `account:` prefix
3. **Transaction commit delay**: Need to wait 10-15 seconds after invoke before querying

## Fixed Chaincode

I've fixed the account ID mismatch issue in the chaincode. The updated chaincode needs to be redeployed.

## Quick Working Commands

### Create Account (use account ID without prefix)
```bash
docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode invoke \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C insurance-channel \
  -n insurance \
  -c '{"function":"CreateAccount","Args":["insurer001","AcmeInsurance","1000000"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt
```

### Create Policy (after account exists, wait 10 seconds)
```bash
sleep 10

docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode invoke \
  -o orderer.example.com:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C insurance-channel \
  -n insurance \
  -c '{"function":"CreatePolicy","Args":["POL001","insurer001","client001","100000","30000","70000"]}' \
  --peerAddresses peer0.insurer.example.com:7051 \
  --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt
```

### Query Policy (wait 15 seconds after create)
```bash
sleep 15

docker exec -e CORE_PEER_LOCALMSPID=InsurerOrgMSP \
  -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt \
  -e CORE_PEER_TLS_ENABLED=true \
  cli peer chaincode query \
  -C insurance-channel \
  -n insurance \
  -c '{"function":"GetPolicy","Args":["POL001"]}'
```

## Key Points

1. **Always use `{"function":"...","Args":[...]}` format**
2. **Use only ONE peer for invoke** (avoid timestamp mismatch)
3. **Wait 10-15 seconds** between invoke and query
4. **Account IDs**: Use `insurer001` (not `account_insurer001`) - the chaincode adds the `account:` prefix internally

## Next Steps

The chaincode has been fixed but needs to be redeployed. See `PLAY_WITH_NETWORK.md` for the complete workflow once the chaincode is updated.

