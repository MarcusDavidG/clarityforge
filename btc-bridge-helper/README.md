# BTC Bridge Helper - Cross-Chain Message Formatter

**Built for Stacks Builder Challenge by Marcus David**

## Deployed Contract

**Testnet Address:** `ST3P3DPDB69YP0Z259SS6MSA16GBQEBF8KG8P96D2.btc-bridge-helper`

**Explorer:** [View on Stacks Explorer](https://explorer.hiro.so/txid/ST3P3DPDB69YP0Z259SS6MSA16GBQEBF8KG8P96D2.btc-bridge-helper?chain=testnet)

**Deployer:** `ST3P3DPDB69YP0Z259SS6MSA16GBQEBF8KG8P96D2`

##  Overview
A cross-chain messaging and formatting system for Bitcoin-Stacks interoperability. Handles Bitcoin address validation, message formatting, and cross-chain data conversion. Showcases **Clarity 4's to-ascii** string conversion functionality.

##  Key Features
- **Cross-chain messaging**: Format data for Bitcoin/Stacks communication
- **String conversion**: Convert uints to ASCII (Clarity 4 feature)
- ₿ **Bitcoin address validation**: Verify BTC address format
- **Message tracking**: Store and confirm cross-chain messages
- **Bridge fees**: Configurable fee system for sustainability

##  Use Cases
- sBTC bridge operations
- Bitcoin address formatting
- Cross-chain message passing
- Transaction ID formatting for display
- Bridge fee collection

##  Contract Functions

### Public Functions
- `create-message(btc-address, amount, message-data)` - Create cross-chain message
- `confirm-message(msg-id)` - Confirm message received (owner only)
- `get-formatted-message(msg-id)` - Retrieve formatted message data
- `set-bridge-fee(fee)` - Update bridge fee (owner only)
- `withdraw-fees(amount)` - Withdraw collected fees (owner only)

### Read-Only Functions
- `format-amount(amount)` - Format uint for display
- `format-block-height(height)` - Format block height
- `format-tx-info(tx-id, amount, height)` - Format transaction info
- `validate-btc-address(btc-addr)` - Validate Bitcoin address format
- `get-message(msg-id)` - Get message details
- `get-user-messages(user)` - List user's messages
- `get-bridge-stats()` - Get bridge statistics

##  Message States

- **0 - Pending**: Message created, awaiting confirmation
- **1 - Confirmed**: Message confirmed on other chain
- **2 - Failed**: Message processing failed

##  How It Works

### Creating a Message
1. User provides Bitcoin address and amount
2. Contract validates BTC address format
3. User pays bridge fee (1 STX default)
4. Message stored with formatted data
5. Message ID returned for tracking

### Formatting Features
- Converts amounts to displayable format
- Formats timestamps for readability
- Validates Bitcoin address structure
- Stores transaction hashes

##  Bitcoin Address Validation
- Checks address length (26-62 characters)
- Validates format structure
- Prevents invalid addresses
- Returns clear error messages

##  Bridge Fees
- Default: 1 STX per message
- Configurable by contract owner
- Collected for operational costs
- Withdrawable by owner

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
- **String conversion** patterns (Clarity 4 uses `to-ascii`)
- **Cross-chain data formatting**
- **Bitcoin address handling**
- **Bridge infrastructure** patterns

##  Integration Example

```clarity
;; Create a cross-chain message
(contract-call? .btc-bridge-helper create-message 
  "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"  ;; BTC address
  u1000000                                        ;; 1 STX in microSTX
  0x1234...                                       ;; Message hash
)

;; Get formatted message
(contract-call? .btc-bridge-helper get-formatted-message u1)
```

##  Future Enhancements
- sBTC integration
- Multi-chain support
- Automatic message relaying
- Advanced formatting options
- Fee token customization

##  Built For
-  Stacks Builder Challenge (Dec 10-14, 2024)
-  Demonstrating Bitcoin-Stacks interoperability

##  License
MIT License

##  Author
Marcus David
