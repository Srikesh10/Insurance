/*
 * Copyright IBM Corp All Rights Reserved
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Parametric Cyber Insurance Chaincode
 * Implements a two-tier parametric insurance system with automated Tier1 payouts
 * and consensus-based Tier2 payouts for cyber insurance claims.
 */

package main

import (
	// Forced rebuild for deployment
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/v2/contractapi"
)

// InsuranceContract provides functions for managing cyber insurance policies and claims
type InsuranceContract struct {
	contractapi.Contract
}

// InsurancePolicy represents an insurance policy
type InsurancePolicy struct {
	PolicyID           string   `json:"policyId"`
	Insurer            string   `json:"insurer"`
	Client             string   `json:"client"`
	CoverageAmount     float64  `json:"coverageAmount"`
	Tier1Amount        float64  `json:"tier1Amount"`
	Tier2Amount        float64  `json:"tier2Amount"`
	ParametricTriggers []string `json:"parametricTriggers"` // List of threat types that trigger automatic Tier1
	Status             string   `json:"status"`             // "active", "expired", "cancelled"
}

// IncidentReport represents an incident report submitted with a claim
type IncidentReport struct {
	ReportID             string    `json:"reportId"`
	Timestamp            time.Time `json:"timestamp"`
	ThreatType           string    `json:"threatType"`
	AffectedSystems      []string  `json:"affectedSystems"`
	EncryptionPercentage float64   `json:"encryptionPercentage"`
	EstimatedImpact      float64   `json:"estimatedImpact"`
	EvidenceHashes       []string  `json:"evidenceHashes"`
}

// Claim represents an insurance claim
type Claim struct {
	ClaimID           string          `json:"claimId"`
	PolicyID          string          `json:"policyId"`
	IncidentReport    IncidentReport  `json:"incidentReport"`
	Tier1Status       string          `json:"tier1Status"` // "pending", "approved", "denied", "paid"
	Tier1Amount       float64         `json:"tier1Amount"`
	Tier2Status       string          `json:"tier2Status"` // "pending", "approved", "denied", "paid"
	Tier2Amount       float64         `json:"tier2Amount"`
	VerifierApprovals map[string]bool `json:"verifierApprovals"` // Map of verifierOrg -> approval status
}

// Account represents a financial account in the system
type Account struct {
	AccountID string    `json:"accountId"`
	Owner     string    `json:"owner"` // MSP ID of owning organization
	Balance   float64   `json:"balance"`
	CreatedAt time.Time `json:"createdAt"`
}

// Transaction represents a fund transfer transaction
type Transaction struct {
	TxID      string    `json:"txId"`
	From      string    `json:"from"` // Account ID
	To        string    `json:"to"`   // Account ID
	Amount    float64   `json:"amount"`
	Timestamp time.Time `json:"timestamp"`
	Purpose   string    `json:"purpose"`           // e.g., "Tier1Payout", "Tier2Payout", "Transfer"
	ClaimID   string    `json:"claimId,omitempty"` // Optional: link to claim
}

// CreatePolicy creates a new insurance policy
func (s *InsuranceContract) CreatePolicy(
	ctx contractapi.TransactionContextInterface,
	policyId string,
	insurer string,
	client string,
	coverageAmount float64,
	tier1Amount float64,
	tier2Amount float64,
) error {
	log.Printf("CreatePolicy called: policyId=%s, insurer=%s, client=%s", policyId, insurer, client)

	// Validate inputs
	if policyId == "" {
		return fmt.Errorf("policyId cannot be empty")
	}
	if insurer == "" {
		return fmt.Errorf("insurer cannot be empty")
	}
	if client == "" {
		return fmt.Errorf("client cannot be empty")
	}
	if coverageAmount <= 0 {
		return fmt.Errorf("coverageAmount must be positive")
	}
	if tier1Amount < 0 || tier2Amount < 0 {
		return fmt.Errorf("tier amounts cannot be negative")
	}
	if tier1Amount+tier2Amount > coverageAmount {
		return fmt.Errorf("tier1Amount + tier2Amount cannot exceed coverageAmount")
	}

	// Check if policy already exists
	policyKey := "policy:" + policyId
	existingPolicy, err := ctx.GetStub().GetState(policyKey)
	if err != nil {
		return fmt.Errorf("failed to read from world state: %v", err)
	}
	if existingPolicy != nil {
		return fmt.Errorf("policy %s already exists", policyId)
	}

	// Validate insurer has sufficient balance to cover policy
	insurerAccountId := insurer // Use insurer ID directly, account key will be "account:" + insurerAccountId
	insurerAccount, err := s.getAccount(ctx, insurerAccountId)
	if err == nil {
		// Account exists, check balance
		if insurerAccount.Balance < coverageAmount {
			return fmt.Errorf("insurer account %s has insufficient balance: have %.2f, need %.2f",
				insurerAccountId, insurerAccount.Balance, coverageAmount)
		}
		log.Printf("Insurer account validated: balance=%.2f, coverage=%.2f", insurerAccount.Balance, coverageAmount)
	} else {
		log.Printf("Warning: Insurer account %s does not exist, skipping balance validation", insurerAccountId)
	}

	// Create new policy
	policy := InsurancePolicy{
		PolicyID:           policyId,
		Insurer:            insurer,
		Client:             client,
		CoverageAmount:     coverageAmount,
		Tier1Amount:        tier1Amount,
		Tier2Amount:        tier2Amount,
		ParametricTriggers: []string{"ransomware", "data_breach"}, // Default triggers for automated payouts
		Status:             "active",
	}

	policyJSON, err := json.Marshal(policy)
	if err != nil {
		return fmt.Errorf("failed to marshal policy: %v", err)
	}

	err = ctx.GetStub().PutState(policyKey, policyJSON)
	if err != nil {
		return fmt.Errorf("failed to put policy to world state: %v", err)
	}

	log.Printf("Policy created successfully: %s", policyId)
	return nil
}

// SubmitClaim submits a new claim with incident report data
func (s *InsuranceContract) SubmitClaim(
	ctx contractapi.TransactionContextInterface,
	policyId string,
	incidentReportJSON string,
) (string, error) {
	log.Printf("SubmitClaim called: policyId=%s", policyId)
	
	// Access Control: Only Trusted Oracle (SOCOrgMSP) can submit verified claims
	// This solves the 'Oracle Problem' by preventing clients from self-reporting
	clientMSPID, mspErr := ctx.GetClientIdentity().GetMSPID()
	if mspErr != nil {
		return "", fmt.Errorf("failed to get client identity: %v", mspErr)
	}
	if clientMSPID != "SOCOrgMSP" {
		return "", fmt.Errorf("access denied: only SOCOrgMSP can submit claims (Oracle Pattern). You are %s", clientMSPID)
	}

	// Parse incident report
	var incidentReport IncidentReport
	err := json.Unmarshal([]byte(incidentReportJSON), &incidentReport)
	if err != nil {
		return "", fmt.Errorf("failed to unmarshal incident report: %v", err)
	}

	// Validate incident report
	if incidentReport.ReportID == "" {
		return "", fmt.Errorf("reportId cannot be empty")
	}
	if incidentReport.ThreatType == "" {
		return "", fmt.Errorf("threatType cannot be empty")
	}
	if incidentReport.EncryptionPercentage < 0 || incidentReport.EncryptionPercentage > 100 {
		return "", fmt.Errorf("encryptionPercentage must be between 0 and 100")
	}

	// Get policy
	policyKey := "policy:" + policyId
	policyJSON, err := ctx.GetStub().GetState(policyKey)
	if err != nil {
		return "", fmt.Errorf("failed to read policy from world state: %v", err)
	}
	if policyJSON == nil {
		return "", fmt.Errorf("policy %s does not exist", policyId)
	}

	var policy InsurancePolicy
	err = json.Unmarshal(policyJSON, &policy)
	if err != nil {
		return "", fmt.Errorf("failed to unmarshal policy: %v", err)
	}

	if policy.Status != "active" {
		return "", fmt.Errorf("policy %s is not active (status: %s)", policyId, policy.Status)
	}

	// Generate claim ID: policyId-reportId format
	claimId := policyId + "-" + incidentReport.ReportID

	// Check if claim already exists
	existingClaim, err := ctx.GetStub().GetState(claimId)
	if err != nil {
		return "", fmt.Errorf("failed to read from world state: %v", err)
	}
	if existingClaim != nil {
		return "", fmt.Errorf("claim %s already exists", claimId)
	}

	// Create new claim
	claim := Claim{
		ClaimID:           claimId,
		PolicyID:          policyId,
		IncidentReport:    incidentReport,
		Tier1Status:       "pending",
		Tier1Amount:       policy.Tier1Amount,
		Tier2Status:       "pending",
		Tier2Amount:       policy.Tier2Amount,
		VerifierApprovals: make(map[string]bool),
	}

	claimJSON, err := json.Marshal(claim)
	if err != nil {
		return "", fmt.Errorf("failed to marshal claim: %v", err)
	}

	err = ctx.GetStub().PutState(claimId, claimJSON)
	if err != nil {
		return "", fmt.Errorf("failed to put claim to world state: %v", err)
	}

	log.Printf("Claim submitted successfully: %s", claimId)
	return claimId, nil
}

// EvaluateTier1Payout checks parametric triggers and approves/denies tier1 payout
func (s *InsuranceContract) EvaluateTier1Payout(
	ctx contractapi.TransactionContextInterface,
	claimId string,
) error {
	log.Printf("EvaluateTier1Payout called: claimId=%s", claimId)

	// Get claim
	claimJSON, err := ctx.GetStub().GetState(claimId)
	if err != nil {
		return fmt.Errorf("failed to read claim from world state: %v", err)
	}
	if claimJSON == nil {
		return fmt.Errorf("claim %s does not exist", claimId)
	}

	var claim Claim
	err = json.Unmarshal(claimJSON, &claim)
	if err != nil {
		return fmt.Errorf("failed to unmarshal claim: %v", err)
	}

	// Check if already evaluated
	if claim.Tier1Status != "pending" {
		return fmt.Errorf("tier1 for claim %s already evaluated (status: %s)", claimId, claim.Tier1Status)
	}

	// Get policy
	policyKey := "policy:" + claim.PolicyID
	policyJSON, err := ctx.GetStub().GetState(policyKey)
	if err != nil {
		return fmt.Errorf("failed to read policy from world state: %v", err)
	}
	if policyJSON == nil {
		return fmt.Errorf("policy %s does not exist", claim.PolicyID)
	}

	var policy InsurancePolicy
	err = json.Unmarshal(policyJSON, &policy)
	if err != nil {
		return fmt.Errorf("failed to unmarshal policy: %v", err)
	}

	// Parametric trigger logic
	approved := false
	reason := ""

	// Check if threatType matches policy triggers
	threatMatches := false
	for _, trigger := range policy.ParametricTriggers {
		if trigger == claim.IncidentReport.ThreatType {
			threatMatches = true
			break
		}
	}

	// Check if encryptionPercentage > 50%
	encryptionThresholdMet := claim.IncidentReport.EncryptionPercentage > 50.0

	// Auto-approve if both conditions are met
	if threatMatches && encryptionThresholdMet {
		approved = true
		reason = "Parametric triggers met: threatType matches policy triggers and encryptionPercentage > 50%"
		log.Printf("Tier1 approved: %s", reason)
	} else {
		approved = false
		if !threatMatches {
			reason = fmt.Sprintf("Threat type '%s' does not match policy triggers", claim.IncidentReport.ThreatType)
		} else if !encryptionThresholdMet {
			reason = fmt.Sprintf("Encryption percentage %.2f%% is not greater than 50%%", claim.IncidentReport.EncryptionPercentage)
		}
		log.Printf("Tier1 denied: %s", reason)
	}

	// Update claim status
	if approved {
		claim.Tier1Status = "approved"
	} else {
		claim.Tier1Status = "denied"
	}

	claimJSON, err = json.Marshal(claim)
	if err != nil {
		return fmt.Errorf("failed to marshal updated claim: %v", err)
	}

	err = ctx.GetStub().PutState(claimId, claimJSON)
	if err != nil {
		return fmt.Errorf("failed to update claim in world state: %v", err)
	}

	log.Printf("Tier1 evaluation completed: claimId=%s, status=%s", claimId, claim.Tier1Status)
	return nil
}

// ExecuteTier1Payout releases tier1 funds after approval
func (s *InsuranceContract) ExecuteTier1Payout(
	ctx contractapi.TransactionContextInterface,
	claimId string,
) error {
	log.Printf("ExecuteTier1Payout called: claimId=%s", claimId)

	// Get claim
	claimJSON, err := ctx.GetStub().GetState(claimId)
	if err != nil {
		return fmt.Errorf("failed to read claim from world state: %v", err)
	}
	if claimJSON == nil {
		return fmt.Errorf("claim %s does not exist", claimId)
	}

	var claim Claim
	err = json.Unmarshal(claimJSON, &claim)
	if err != nil {
		return fmt.Errorf("failed to unmarshal claim: %v", err)
	}

	// Check if tier1 is approved
	if claim.Tier1Status != "approved" {
		return fmt.Errorf("tier1 for claim %s is not approved (status: %s)", claimId, claim.Tier1Status)
	}

	// Check if already paid
	if claim.Tier1Status == "paid" {
		return fmt.Errorf("tier1 for claim %s has already been paid", claimId)
	}

	// Get policy to determine insurer and client
	policyKey := "policy:" + claim.PolicyID
	policyJSON, err := ctx.GetStub().GetState(policyKey)
	if err != nil {
		return fmt.Errorf("failed to read policy from world state: %v", err)
	}
	if policyJSON == nil {
		return fmt.Errorf("policy %s does not exist", claim.PolicyID)
	}

	var policy InsurancePolicy
	err = json.Unmarshal(policyJSON, &policy)
	if err != nil {
		return fmt.Errorf("failed to unmarshal policy: %v", err)
	}

	// Determine account IDs
	insurerAccountId := policy.Insurer
	clientAccountId := policy.Client

	// Transfer funds from insurer to client
	err = s.Transfer(ctx, insurerAccountId, clientAccountId, claim.Tier1Amount, "Tier1Payout", claimId)
	if err != nil {
		return fmt.Errorf("failed to transfer funds for Tier1 payout: %v", err)
	}

	// Update claim status to paid only if transfer succeeded
	claim.Tier1Status = "paid"

	claimJSON, err = json.Marshal(claim)
	if err != nil {
		return fmt.Errorf("failed to marshal updated claim: %v", err)
	}

	err = ctx.GetStub().PutState(claimId, claimJSON)
	if err != nil {
		return fmt.Errorf("failed to update claim in world state: %v", err)
	}

	log.Printf("Tier1 payout executed successfully: claimId=%s, amount=%.2f, from=%s, to=%s",
		claimId, claim.Tier1Amount, insurerAccountId, clientAccountId)
	return nil
}

// VerifyForTier2 allows a verifier organization to approve or deny tier2 payout
func (s *InsuranceContract) VerifyForTier2(
	ctx contractapi.TransactionContextInterface,
	claimId string,
	verifierOrg string,
	approval bool,
) error {
	log.Printf("VerifyForTier2 called: claimId=%s, verifierOrg=%s, approval=%t", claimId, verifierOrg, approval)

	if verifierOrg == "" {
		return fmt.Errorf("verifierOrg cannot be empty")
	}

	// Get claim
	claimJSON, err := ctx.GetStub().GetState(claimId)
	if err != nil {
		return fmt.Errorf("failed to read claim from world state: %v", err)
	}
	if claimJSON == nil {
		return fmt.Errorf("claim %s does not exist", claimId)
	}

	var claim Claim
	err = json.Unmarshal(claimJSON, &claim)
	if err != nil {
		return fmt.Errorf("failed to unmarshal claim: %v", err)
	}

	// Initialize verifier approvals map if nil
	if claim.VerifierApprovals == nil {
		claim.VerifierApprovals = make(map[string]bool)
	}

	// Record verifier approval
	claim.VerifierApprovals[verifierOrg] = approval

	// Check if tier2 can be approved (consensus mechanism)
	// For now, we require at least 2 approvals with majority being positive
	// This can be customized based on business requirements
	approvalCount := 0
	totalVerifiers := len(claim.VerifierApprovals)

	for _, approved := range claim.VerifierApprovals {
		if approved {
			approvalCount++
		}
	}

	// Update tier2 status based on consensus
	// Require at least 2 verifiers and majority approval
	if totalVerifiers >= 2 {
		if approvalCount > totalVerifiers/2 {
			claim.Tier2Status = "approved"
			log.Printf("Tier2 approved by consensus: %d/%d verifiers approved", approvalCount, totalVerifiers)
		} else {
			claim.Tier2Status = "denied"
			log.Printf("Tier2 denied by consensus: %d/%d verifiers approved", approvalCount, totalVerifiers)
		}
	} else {
		claim.Tier2Status = "pending"
		log.Printf("Tier2 still pending: %d verifier(s), need at least 2", totalVerifiers)
	}

	claimJSON, err = json.Marshal(claim)
	if err != nil {
		return fmt.Errorf("failed to marshal updated claim: %v", err)
	}

	err = ctx.GetStub().PutState(claimId, claimJSON)
	if err != nil {
		return fmt.Errorf("failed to update claim in world state: %v", err)
	}

	log.Printf("Verification recorded: claimId=%s, verifierOrg=%s, approval=%t", claimId, verifierOrg, approval)
	return nil
}

// ExecuteTier2Payout releases tier2 funds after verification and approval
func (s *InsuranceContract) ExecuteTier2Payout(
	ctx contractapi.TransactionContextInterface,
	claimId string,
) error {
	log.Printf("ExecuteTier2Payout called: claimId=%s", claimId)

	// Get claim
	claimJSON, err := ctx.GetStub().GetState(claimId)
	if err != nil {
		return fmt.Errorf("failed to read claim from world state: %v", err)
	}
	if claimJSON == nil {
		return fmt.Errorf("claim %s does not exist", claimId)
	}

	var claim Claim
	err = json.Unmarshal(claimJSON, &claim)
	if err != nil {
		return fmt.Errorf("failed to unmarshal claim: %v", err)
	}

	// Check if tier2 is approved
	if claim.Tier2Status != "approved" {
		return fmt.Errorf("tier2 for claim %s is not approved (status: %s)", claimId, claim.Tier2Status)
	}

	// Check if already paid
	if claim.Tier2Status == "paid" {
		return fmt.Errorf("tier2 for claim %s has already been paid", claimId)
	}

	// Get policy to determine insurer and client
	policyKey := "policy:" + claim.PolicyID
	policyJSON, err := ctx.GetStub().GetState(policyKey)
	if err != nil {
		return fmt.Errorf("failed to read policy from world state: %v", err)
	}
	if policyJSON == nil {
		return fmt.Errorf("policy %s does not exist", claim.PolicyID)
	}

	var policy InsurancePolicy
	err = json.Unmarshal(policyJSON, &policy)
	if err != nil {
		return fmt.Errorf("failed to unmarshal policy: %v", err)
	}

	// Determine account IDs
	insurerAccountId := policy.Insurer
	clientAccountId := policy.Client

	// Transfer funds from insurer to client
	err = s.Transfer(ctx, insurerAccountId, clientAccountId, claim.Tier2Amount, "Tier2Payout", claimId)
	if err != nil {
		return fmt.Errorf("failed to transfer funds for Tier2 payout: %v", err)
	}

	// Update claim status to paid only if transfer succeeded
	claim.Tier2Status = "paid"

	claimJSON, err = json.Marshal(claim)
	if err != nil {
		return fmt.Errorf("failed to marshal updated claim: %v", err)
	}

	err = ctx.GetStub().PutState(claimId, claimJSON)
	if err != nil {
		return fmt.Errorf("failed to update claim in world state: %v", err)
	}

	log.Printf("Tier2 payout executed successfully: claimId=%s, amount=%.2f, from=%s, to=%s",
		claimId, claim.Tier2Amount, insurerAccountId, clientAccountId)
	return nil
}

// GetPolicy retrieves a policy from the ledger
func (s *InsuranceContract) GetPolicy(
	ctx contractapi.TransactionContextInterface,
	policyId string,
) (*InsurancePolicy, error) {
	policyKey := "policy:" + policyId
	policyJSON, err := ctx.GetStub().GetState(policyKey)
	if err != nil {
		return nil, fmt.Errorf("failed to read policy from world state: %v", err)
	}
	if policyJSON == nil {
		return nil, fmt.Errorf("policy %s does not exist", policyId)
	}

	var policy InsurancePolicy
	err = json.Unmarshal(policyJSON, &policy)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal policy: %v", err)
	}

	return &policy, nil
}

// GetClaim retrieves a claim from the ledger
func (s *InsuranceContract) GetClaim(
	ctx contractapi.TransactionContextInterface,
	claimId string,
) (*Claim, error) {
	claimJSON, err := ctx.GetStub().GetState(claimId)
	if err != nil {
		return nil, fmt.Errorf("failed to read claim from world state: %v", err)
	}
	if claimJSON == nil {
		return nil, fmt.Errorf("claim %s does not exist", claimId)
	}

	var claim Claim
	err = json.Unmarshal(claimJSON, &claim)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal claim: %v", err)
	}

	return &claim, nil
}

// ============================================================================
// ACCOUNT MANAGEMENT FUNCTIONS
// ============================================================================

// CreateAccount creates a new account with an initial balance
func (s *InsuranceContract) CreateAccount(
	ctx contractapi.TransactionContextInterface,
	accountId string,
	owner string,
	initialBalance float64,
) error {
	log.Printf("CreateAccount called: accountId=%s, owner=%s, initialBalance=%.2f", accountId, owner, initialBalance)

	// Validate inputs
	if accountId == "" {
		return fmt.Errorf("accountId cannot be empty")
	}
	if owner == "" {
		return fmt.Errorf("owner cannot be empty")
	}
	if initialBalance < 0 {
		return fmt.Errorf("initialBalance cannot be negative")
	}

	// Check if account already exists
	accountKey := "account:" + accountId
	existingAccount, err := ctx.GetStub().GetState(accountKey)
	if err != nil {
		return fmt.Errorf("failed to read from world state: %v", err)
	}
	if existingAccount != nil {
		return fmt.Errorf("account %s already exists", accountId)
	}

	// Create new account
	account := Account{
		AccountID: accountId,
		Owner:     owner,
		Balance:   initialBalance,
		CreatedAt: time.Now(),
	}

	accountJSON, err := json.Marshal(account)
	if err != nil {
		return fmt.Errorf("failed to marshal account: %v", err)
	}

	err = ctx.GetStub().PutState(accountKey, accountJSON)
	if err != nil {
		return fmt.Errorf("failed to put account to world state: %v", err)
	}

	log.Printf("Account created successfully: %s with balance %.2f", accountId, initialBalance)
	return nil
}

// GetAccount retrieves an account from the ledger
func (s *InsuranceContract) GetAccount(
	ctx contractapi.TransactionContextInterface,
	accountId string,
) (*Account, error) {
	account, err := s.getAccount(ctx, accountId)
	if err != nil {
		return nil, err
	}
	return account, nil
}

// getAccount is a helper function to retrieve account (used internally)
func (s *InsuranceContract) getAccount(
	ctx contractapi.TransactionContextInterface,
	accountId string,
) (*Account, error) {
	accountKey := "account:" + accountId
	accountJSON, err := ctx.GetStub().GetState(accountKey)
	if err != nil {
		return nil, fmt.Errorf("failed to read account from world state: %v", err)
	}
	if accountJSON == nil {
		return nil, fmt.Errorf("account %s does not exist", accountId)
	}

	var account Account
	err = json.Unmarshal(accountJSON, &account)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal account: %v", err)
	}

	return &account, nil
}

// GetBalance retrieves the balance of an account
func (s *InsuranceContract) GetBalance(
	ctx contractapi.TransactionContextInterface,
	accountId string,
) (float64, error) {
	account, err := s.getAccount(ctx, accountId)
	if err != nil {
		return 0, err
	}
	return account.Balance, nil
}

// GetAllAccounts retrieves all accounts from the ledger (for demo purposes)
func (s *InsuranceContract) GetAllAccounts(
	ctx contractapi.TransactionContextInterface,
) ([]*Account, error) {
	log.Printf("GetAllAccounts called")

	// Use range query to get all accounts
	iterator, err := ctx.GetStub().GetStateByRange("account:", "account:~")
	if err != nil {
		return nil, fmt.Errorf("failed to get state by range: %v", err)
	}
	defer iterator.Close()

	var accounts []*Account
	for iterator.HasNext() {
		queryResponse, err := iterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to get next result: %v", err)
		}

		var account Account
		err = json.Unmarshal(queryResponse.Value, &account)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal account: %v", err)
		}

		accounts = append(accounts, &account)
	}

	log.Printf("Retrieved %d accounts", len(accounts))
	return accounts, nil
}

// ============================================================================
// TRANSFER FUNCTIONS
// ============================================================================

// Transfer moves funds from one account to another
func (s *InsuranceContract) Transfer(
	ctx contractapi.TransactionContextInterface,
	fromAccountId string,
	toAccountId string,
	amount float64,
	purpose string,
	claimId string,
) error {
	log.Printf("Transfer called: from=%s, to=%s, amount=%.2f, purpose=%s",
		fromAccountId, toAccountId, amount, purpose)

	// Validate inputs
	if amount <= 0 {
		return fmt.Errorf("amount must be positive")
	}
	if fromAccountId == "" {
		return fmt.Errorf("fromAccountId cannot be empty")
	}
	if toAccountId == "" {
		return fmt.Errorf("toAccountId cannot be empty")
	}
	if fromAccountId == toAccountId {
		return fmt.Errorf("cannot transfer to the same account")
	}

	// Get from account
	fromAccount, err := s.getAccount(ctx, fromAccountId)
	if err != nil {
		return fmt.Errorf("failed to get from account: %v", err)
	}

	// Get to account
	toAccount, err := s.getAccount(ctx, toAccountId)
	if err != nil {
		return fmt.Errorf("failed to get to account: %v", err)
	}

	// Check sufficient balance
	if fromAccount.Balance < amount {
		return fmt.Errorf("insufficient balance in account %s: have %.2f, need %.2f",
			fromAccountId, fromAccount.Balance, amount)
	}

	// Update balances atomically
	fromAccount.Balance -= amount
	toAccount.Balance += amount

	// Validate no negative balances
	if fromAccount.Balance < 0 {
		return fmt.Errorf("transfer would result in negative balance")
	}

	// Save from account
	fromAccountJSON, err := json.Marshal(fromAccount)
	if err != nil {
		return fmt.Errorf("failed to marshal from account: %v", err)
	}
	err = ctx.GetStub().PutState("account:"+fromAccountId, fromAccountJSON)
	if err != nil {
		return fmt.Errorf("failed to update from account: %v", err)
	}

	// Save to account
	toAccountJSON, err := json.Marshal(toAccount)
	if err != nil {
		return fmt.Errorf("failed to marshal to account: %v", err)
	}
	err = ctx.GetStub().PutState("account:"+toAccountId, toAccountJSON)
	if err != nil {
		return fmt.Errorf("failed to update to account: %v", err)
	}

	// Create transaction record
	txId := ctx.GetStub().GetTxID()
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	var transactionTime time.Time
	if err != nil {
		transactionTime = time.Now()
	} else {
		transactionTime = time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))
	}

	transaction := Transaction{
		TxID:      txId,
		From:      fromAccountId,
		To:        toAccountId,
		Amount:    amount,
		Timestamp: transactionTime,
		Purpose:   purpose,
		ClaimID:   claimId,
	}

	transactionJSON, err := json.Marshal(transaction)
	if err != nil {
		return fmt.Errorf("failed to marshal transaction: %v", err)
	}

	txKey := "transaction:" + txId
	err = ctx.GetStub().PutState(txKey, transactionJSON)
	if err != nil {
		return fmt.Errorf("failed to record transaction: %v", err)
	}

	log.Printf("Transfer completed: %.2f from %s to %s (txId: %s)",
		amount, fromAccountId, toAccountId, txId)
	return nil
}

func main() {
	insuranceChaincode, err := contractapi.NewChaincode(&InsuranceContract{})
	if err != nil {
		log.Panicf("Error creating insurance chaincode: %v", err)
	}

	if err := insuranceChaincode.Start(); err != nil {
		log.Panicf("Error starting insurance chaincode: %v", err)
	}
}
