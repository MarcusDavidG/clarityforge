# Credential Registry - On-Chain Credentials and Certificates

Issue, verify, and manage digital credentials on the blockchain.

## Features

- **Issuer Registry**: Register and verify credential issuers
- **Multiple Types**: Certificates, licenses, badges, degrees
- **Issue Credentials**: Mint credentials for holders
- **Revocation**: Revoke compromised or invalid credentials
- **Verification**: Third-party verification tracking
- **Expiration**: Optional expiration dates
- **Transferability**: Transfer credentials to new holders

## Key Functions

### register-issuer
Register as a credential issuer.

### issue-credential
Issue a new credential to a holder.

### revoke-credential
Revoke a previously issued credential.

### verify-credential
Third-party verification of credentials.

### transfer-credential
Transfer credential to a new holder.

## Credential Types

- **Certificate**: Completion certificates
- **License**: Professional licenses
- **Badge**: Achievement badges
- **Degree**: Academic degrees

## Use Cases

- Educational certificates
- Professional licenses
- Training completion
- Achievement badges
- Identity verification

## Deployment

```bash
clarinet check
clarinet deploy --testnet
```
