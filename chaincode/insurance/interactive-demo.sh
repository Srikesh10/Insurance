#!/bin/bash
# Interactive Demo Script for Insurance Chaincode
# This script provides an easy way to interact with the insurance chaincode

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Common environment variables
INSURER_ENV="-e CORE_PEER_LOCALMSPID=InsurerOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/insurer.example.com/users/Admin@insurer.example.com/msp -e CORE_PEER_ADDRESS=peer0.insurer.example.com:7051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true"

CLIENT_ENV="-e CORE_PEER_LOCALMSPID=ClientOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/client.example.com/users/Admin@client.example.com/msp -e CORE_PEER_ADDRESS=peer0.client.example.com:7051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true"

REGULATOR_ENV="-e CORE_PEER_LOCALMSPID=RegulatorOrgMSP -e CORE_PEER_MSPCONFIGPATH=/opt/crypto-config/peerOrganizations/regulator.example.com/users/Admin@regulator.example.com/msp -e CORE_PEER_ADDRESS=peer0.regulator.example.com:7051 -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt -e CORE_PEER_TLS_ENABLED=true"

ORDERER_OPTS="-o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /opt/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

PEER_OPTS="--peerAddresses peer0.insurer.example.com:7051 --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt --peerAddresses peer0.client.example.com:7051 --tlsRootCertFiles /opt/crypto-config/peerOrganizations/client.example.com/peers/peer0.client.example.com/tls/ca.crt"

CHANNEL="-C insurance-channel"
CHAINCODE="-n insurance"

echo -e "${BLUE}=== Insurance Chaincode Interactive Demo ===${NC}\n"

# Function to create a policy
create_policy() {
    echo -e "${YELLOW}Creating insurance policy...${NC}"
    read -p "Policy ID: " POLICY_ID
    read -p "Insurer name: " INSURER
    read -p "Client name: " CLIENT
    read -p "Coverage amount: " COVERAGE
    read -p "Tier 1 amount: " TIER1
    read -p "Tier 2 amount: " TIER2
    
    docker exec $INSURER_ENV cli peer chaincode invoke \
        $ORDERER_OPTS \
        $CHANNEL \
        $CHAINCODE \
        -c "{\"Args\":[\"CreatePolicy\",\"$POLICY_ID\",\"$INSURER\",\"$CLIENT\",\"$COVERAGE\",\"$TIER1\",\"$TIER2\"]}" \
        $PEER_OPTS
    
    echo -e "${GREEN}Policy created!${NC}\n"
}

# Function to query a policy
query_policy() {
    read -p "Policy ID to query: " POLICY_ID
    echo -e "${YELLOW}Querying policy $POLICY_ID...${NC}"
    
    docker exec $INSURER_ENV cli peer chaincode query \
        $CHANNEL \
        $CHAINCODE \
        -c "{\"Args\":[\"GetPolicy\",\"$POLICY_ID\"]}"
    
    echo -e "\n${GREEN}Query complete!${NC}\n"
}

# Function to submit a claim
submit_claim() {
    echo -e "${YELLOW}Submitting a claim...${NC}"
    read -p "Policy ID: " POLICY_ID
    read -p "Report ID: " REPORT_ID
    read -p "Threat type (ransomware/phishing/etc): " THREAT_TYPE
    read -p "Encryption percentage: " ENCRYPTION_PCT
    read -p "Estimated impact: " IMPACT
    
    INCIDENT_REPORT="{\"reportId\":\"$REPORT_ID\",\"threatType\":\"$THREAT_TYPE\",\"affectedSystems\":[\"server1\"],\"encryptionPercentage\":$ENCRYPTION_PCT,\"estimatedImpact\":$IMPACT,\"evidenceHashes\":[\"hash1\"]}"
    
    docker exec $CLIENT_ENV cli peer chaincode invoke \
        $ORDERER_OPTS \
        $CHANNEL \
        $CHAINCODE \
        -c "{\"Args\":[\"SubmitClaim\",\"$POLICY_ID\",\"$INCIDENT_REPORT\"]}" \
        $PEER_OPTS
    
    echo -e "${GREEN}Claim submitted! Claim ID: ${POLICY_ID}-${REPORT_ID}${NC}\n"
}

# Function to evaluate Tier 1
evaluate_tier1() {
    read -p "Claim ID (PolicyID-ReportID): " CLAIM_ID
    echo -e "${YELLOW}Evaluating Tier 1 payout for $CLAIM_ID...${NC}"
    
    docker exec $INSURER_ENV cli peer chaincode invoke \
        $ORDERER_OPTS \
        $CHANNEL \
        $CHAINCODE \
        -c "{\"Args\":[\"EvaluateTier1Payout\",\"$CLAIM_ID\"]}" \
        $PEER_OPTS
    
    echo -e "${GREEN}Evaluation complete!${NC}\n"
}

# Function to execute Tier 1
execute_tier1() {
    read -p "Claim ID: " CLAIM_ID
    echo -e "${YELLOW}Executing Tier 1 payout for $CLAIM_ID...${NC}"
    
    docker exec $INSURER_ENV cli peer chaincode invoke \
        $ORDERER_OPTS \
        $CHANNEL \
        $CHAINCODE \
        -c "{\"Args\":[\"ExecuteTier1Payout\",\"$CLAIM_ID\"]}" \
        $PEER_OPTS
    
    echo -e "${GREEN}Tier 1 payout executed!${NC}\n"
}

# Function to verify for Tier 2
verify_tier2() {
    read -p "Claim ID: " CLAIM_ID
    read -p "Organization (InsurerOrgMSP/RegulatorOrgMSP): " ORG
    read -p "Approve? (true/false): " APPROVAL
    
    echo -e "${YELLOW}Recording $ORG verification ($APPROVAL) for $CLAIM_ID...${NC}"
    
    if [ "$ORG" = "InsurerOrgMSP" ]; then
        ENV=$INSURER_ENV
    elif [ "$ORG" = "RegulatorOrgMSP" ]; then
        ENV=$REGULATOR_ENV
        PEER_OPTS="--peerAddresses peer0.insurer.example.com:7051 --tlsRootCertFiles /opt/crypto-config/peerOrganizations/insurer.example.com/peers/peer0.insurer.example.com/tls/ca.crt --peerAddresses peer0.regulator.example.com:7051 --tlsRootCertFiles /opt/crypto-config/peerOrganizations/regulator.example.com/peers/peer0.regulator.example.com/tls/ca.crt"
    fi
    
    docker exec $ENV cli peer chaincode invoke \
        $ORDERER_OPTS \
        $CHANNEL \
        $CHAINCODE \
        -c "{\"Args\":[\"VerifyForTier2\",\"$CLAIM_ID\",\"$ORG\",\"$APPROVAL\"]}" \
        $PEER_OPTS
    
    echo -e "${GREEN}Verification recorded!${NC}\n"
}

# Function to query a claim
query_claim() {
    read -p "Claim ID (PolicyID-ReportID): " CLAIM_ID
    echo -e "${YELLOW}Querying claim $CLAIM_ID...${NC}"
    
    docker exec $CLIENT_ENV cli peer chaincode query \
        $CHANNEL \
        $CHAINCODE \
        -c "{\"Args\":[\"GetClaim\",\"$CLAIM_ID\"]}"
    
    echo -e "\n${GREEN}Query complete!${NC}\n"
}

# Function to run complete demo
run_demo() {
    echo -e "${BLUE}Running complete demo scenario...${NC}\n"
    
    POLICY_ID="DEMO001"
    REPORT_ID="RPT001"
    CLAIM_ID="${POLICY_ID}-${REPORT_ID}"
    
    echo -e "${YELLOW}Step 1: Creating policy...${NC}"
    docker exec $INSURER_ENV cli peer chaincode invoke \
        $ORDERER_OPTS \
        $CHANNEL \
        $CHAINCODE \
        -c "{\"Args\":[\"CreatePolicy\",\"$POLICY_ID\",\"DemoInsurance\",\"DemoClient\",\"100000\",\"30000\",\"70000\"]}" \
        $PEER_OPTS
    
    sleep 2
    
    echo -e "${YELLOW}Step 2: Submitting claim (ransomware, 80% encryption)...${NC}"
    INCIDENT_REPORT="{\"reportId\":\"$REPORT_ID\",\"threatType\":\"ransomware\",\"affectedSystems\":[\"server1\"],\"encryptionPercentage\":80.0,\"estimatedImpact\":50000,\"evidenceHashes\":[\"hash1\"]}"
    docker exec $CLIENT_ENV cli peer chaincode invoke \
        $ORDERER_OPTS \
        $CHANNEL \
        $CHAINCODE \
        -c "{\"Args\":[\"SubmitClaim\",\"$POLICY_ID\",\"$INCIDENT_REPORT\"]}" \
        $PEER_OPTS
    
    sleep 2
    
    echo -e "${YELLOW}Step 3: Evaluating Tier 1 (should auto-approve!)...${NC}"
    docker exec $INSURER_ENV cli peer chaincode invoke \
        $ORDERER_OPTS \
        $CHANNEL \
        $CHAINCODE \
        -c "{\"Args\":[\"EvaluateTier1Payout\",\"$CLAIM_ID\"]}" \
        $PEER_OPTS
    
    sleep 2
    
    echo -e "${YELLOW}Step 4: Executing Tier 1 payout...${NC}"
    docker exec $INSURER_ENV cli peer chaincode invoke \
        $ORDERER_OPTS \
        $CHANNEL \
        $CHAINCODE \
        -c "{\"Args\":[\"ExecuteTier1Payout\",\"$CLAIM_ID\"]}" \
        $PEER_OPTS
    
    sleep 2
    
    echo -e "${YELLOW}Step 5: Querying claim status...${NC}"
    docker exec $CLIENT_ENV cli peer chaincode query \
        $CHANNEL \
        $CHAINCODE \
        -c "{\"Args\":[\"GetClaim\",\"$CLAIM_ID\"]}"
    
    echo -e "\n${GREEN}Demo complete!${NC}\n"
}

# Main menu
while true; do
    echo -e "${BLUE}Choose an option:${NC}"
    echo "1) Create Policy"
    echo "2) Query Policy"
    echo "3) Submit Claim"
    echo "4) Evaluate Tier 1 Payout"
    echo "5) Execute Tier 1 Payout"
    echo "6) Verify for Tier 2"
    echo "7) Query Claim"
    echo "8) Run Complete Demo"
    echo "9) Exit"
    echo -n "Enter choice [1-9]: "
    read choice
    
    case $choice in
        1) create_policy ;;
        2) query_policy ;;
        3) submit_claim ;;
        4) evaluate_tier1 ;;
        5) execute_tier1 ;;
        6) verify_tier2 ;;
        7) query_claim ;;
        8) run_demo ;;
        9) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${YELLOW}Invalid choice!${NC}\n" ;;
    esac
done

