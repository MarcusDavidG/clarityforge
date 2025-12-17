# Contract Verifier - Trust Registry for Stacks

**Built for Stacks Builder Challenge by Marcus David**

## Deployed Contract

**Testnet Address:** `ST3P3DPDB69YP0Z259SS6MSA16GBQEBF8KG8P96D2.contract-verifier`

**Explorer:** [View on Stacks Explorer](https://explorer.hiro.so/txid/ST3P3DPDB69YP0Z259SS6MSA16GBQEBF8KG8P96D2.contract-verifier?chain=testnet)

**Deployer:** `ST3P3DPDB69YP0Z259SS6MSA16GBQEBF8KG8P96D2`

##  Overview
A decentralized contract verification and trust registry system. Auditors can verify smart contracts, community can rate them, and users can check contract trustworthiness before interacting. Showcases **Clarity 4's contract-of** functionality (using code hash patterns).

##  Key Features
- **Contract verification**: Auditors verify contract code hashes
- **Community ratings**: Users rate verified contracts (0-100)
- **Trust levels**: Unverified, Pending, Verified, Audited, Flagged
- **Flag system**: Mark suspicious contracts
- **Auditor reputation**: Track auditor performance
- **Code hash tracking**: Ensure contract integrity

##  Use Cases
- Smart contract security registry
- Community-driven contract ratings
- Auditor marketplace
- Scam prevention system
- Developer reputation building

##  Contract Functions

### Public Functions - Auditors
- `register-auditor()` - Register as a contract auditor
- `submit-for-verification(contract, audit-report-uri)` - Verify a contract
- `mark-audited(contract, rating)` - Upgrade to audited status
- `flag-contract(contract, reason)` - Report suspicious contract

### Public Functions - Community
- `rate-contract(contract, score)` - Community rating (0-100)

### Public Functions - Admin
- `deactivate-auditor(auditor)` - Remove bad auditor

### Read-Only Functions
- `get-contract-info(contract)` - Get verification status
- `verify-contract-code(contract)` - Check if verified
- `get-auditor-info(auditor)` - Get auditor stats
- `get-ratings(contract)` - Get community ratings
- `get-stats()` - Get registry statistics

##  Trust Levels

0. **Unverified** (u0): Not reviewed
1. **Pending** (u1): Verification in progress
2. **Verified** (u2): Basic verification passed
3. **Audited** (u3): Full security audit completed
4. **Flagged** (u4): Reported as suspicious

##  How It Works

### For Auditors
1. Register as auditor
2. Review contract code
3. Submit verification with code hash
4. Track your reputation

### For Users
1. Check contract before interacting
2. View trust level and ratings
3. Read audit reports
4. Make informed decisions

### For Developers
1. Submit contract for verification
2. Build trust with community
3. Earn higher trust levels
4. Display verification badge

##  Auditor Reputation
- Total audits conducted
- Reputation score (starts at 50)
- Active/inactive status
- Can be deactivated by admin

##  Deployment

```bash
# Check contract
clarinet check

# Test locally
clarinet test

# Deploy to testnet
clarinet deploy --testnet
```

##  Clarity 4 Features

This contract demonstrates:
- **Contract code verification** using hash patterns (Clarity 4 uses `contract-of`)
- **On-chain reputation system**
- **Community governance** patterns
- **Multi-stakeholder design**

##  Future Enhancements
- Automatic security scanning
- Integration with audit firms
- NFT badges for verified contracts
- Bounty system for finding bugs
- DAO governance for auditor approval

##  Built For
-  Stacks Builder Challenge (Dec 10-14, 2024)
-  Building trust infrastructure for Stacks ecosystem

##  License
MIT License

##  Author
Marcus David
