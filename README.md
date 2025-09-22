# PropertyEscrow

PropertyEscrow is a smart contract for real estate purchase and sale escrow transactions built on the Stacks blockchain using Clarity. The contract manages secure escrow services for property transactions, holding funds until all conditions are met and facilitating secure transfers between buyers and sellers.

## Description

This smart contract provides a trustless escrow system for real estate transactions. It enables buyers, sellers, and agents to conduct property transactions with built-in security mechanisms, automatic fund management, and condition verification. The contract holds STX tokens in escrow until all transaction conditions are satisfied, ensuring protection for all parties involved.

## Features

- **Secure Escrow Management**: Creates and manages escrow accounts for property transactions
- **Multi-Party Support**: Supports buyer, seller, and agent roles with specific permissions
- **Automated Fund Handling**: Secure STX token deposits, holding, and release mechanisms
- **Condition Verification**: Agent-controlled condition marking and verification system
- **Expiration Management**: Time-based escrow expiration with automatic refund capabilities
- **Transaction States**: Complete transaction lifecycle tracking (pending, funded, completed, cancelled)
- **Security Controls**: Role-based access control and comprehensive error handling
- **Refund Protection**: Automatic buyer refunds for expired or cancelled transactions

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity v2
- **Clarity Version**: 2
- **Epoch**: 2.5
- **Token Standard**: STX (native Stacks tokens)

### Contract Architecture

The contract consists of:
- **Data Maps**: `escrows` and `escrow-funds` for transaction and fund tracking
- **Constants**: Error codes and access control definitions
- **Public Functions**: Core escrow operations (create, fund, release, cancel)
- **Read-Only Functions**: Query functions for escrow status and details

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) CLI tool
- Node.js (for testing)
- Stacks Wallet or compatible wallet

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd PropertyEscrow
```

2. Install dependencies:
```bash
cd PropertyEscrow_contract
npm install
```

3. Verify contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

## Usage Examples

### Creating an Escrow

```clarity
;; Create a new escrow for a property transaction
(contract-call? .PropertyEscrow create-escrow
    'SP1BUYER123...     ;; buyer principal
    'SP1SELLER456...    ;; seller principal
    'SP1AGENT789...     ;; agent principal
    "PROP-001"          ;; property ID
    u1000000            ;; amount in microSTX (1 STX)
    u144                ;; duration in blocks (~24 hours)
)
```

### Funding an Escrow

```clarity
;; Buyer funds the escrow (must be called by buyer)
(contract-call? .PropertyEscrow fund-escrow u1)
```

### Marking Conditions as Met

```clarity
;; Agent marks all conditions as satisfied
(contract-call? .PropertyEscrow mark-conditions-met u1)
```

### Releasing Funds

```clarity
;; Agent releases funds to seller after conditions are met
(contract-call? .PropertyEscrow release-funds u1)
```

### Cancelling an Escrow

```clarity
;; Cancel escrow and refund buyer (if expired or conditions not met)
(contract-call? .PropertyEscrow cancel-escrow u1)
```

## Contract Functions Documentation

### Public Functions

#### `create-escrow`
Creates a new escrow for a property transaction.

**Parameters:**
- `buyer` (principal): The buyer's address
- `seller` (principal): The seller's address
- `agent` (principal): The escrow agent's address
- `property-id` (string-ascii 50): Unique property identifier
- `amount` (uint): Escrow amount in microSTX
- `duration-blocks` (uint): Escrow duration in blocks

**Returns:** `(response uint uint)` - Escrow ID on success

#### `fund-escrow`
Allows the buyer to deposit STX into the escrow.

**Parameters:**
- `escrow-id` (uint): The escrow identifier

**Access:** Buyer only
**Returns:** `(response bool uint)`

#### `mark-conditions-met`
Marks all escrow conditions as satisfied.

**Parameters:**
- `escrow-id` (uint): The escrow identifier

**Access:** Agent only
**Returns:** `(response bool uint)`

#### `release-funds`
Releases escrowed funds to the seller.

**Parameters:**
- `escrow-id` (uint): The escrow identifier

**Access:** Agent only
**Requirements:** Conditions must be met
**Returns:** `(response bool uint)`

#### `cancel-escrow`
Cancels the escrow and refunds the buyer.

**Parameters:**
- `escrow-id` (uint): The escrow identifier

**Access:** Buyer or Agent
**Returns:** `(response bool uint)`

### Read-Only Functions

#### `get-escrow`
Retrieves complete escrow details.

**Parameters:**
- `escrow-id` (uint): The escrow identifier

**Returns:** `(optional {...})` - Escrow details or none

#### `get-escrow-funds`
Gets the current fund amount for an escrow.

**Parameters:**
- `escrow-id` (uint): The escrow identifier

**Returns:** `(optional {amount: uint})`

#### `get-next-escrow-id`
Returns the next available escrow ID.

**Returns:** `uint`

#### `get-escrow-status`
Gets the current status of an escrow.

**Parameters:**
- `escrow-id` (uint): The escrow identifier

**Returns:** `(optional (string-ascii 20))` - Status string

#### `is-escrow-expired`
Checks if an escrow has expired.

**Parameters:**
- `escrow-id` (uint): The escrow identifier

**Returns:** `bool`

### Escrow States

- **pending**: Escrow created, awaiting funding
- **funded**: Buyer has deposited STX tokens
- **completed**: Funds released to seller
- **cancelled**: Escrow cancelled, funds refunded

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
::deploy_contract PropertyEscrow
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`

2. Deploy using Clarinet:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`

2. Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

## Security Notes

### Access Controls
- **Buyer**: Can only fund and cancel escrows they created
- **Seller**: Receives funds upon successful completion
- **Agent**: Controls condition verification and fund release

### Security Features
- Time-based expiration prevents indefinite fund locking
- Role-based permissions prevent unauthorized actions
- Automatic refunds protect buyer investments
- Comprehensive error handling prevents invalid state transitions

### Important Considerations

1. **Agent Trust**: The agent role has significant control over fund release
2. **Expiration Timing**: Ensure adequate duration for transaction completion
3. **Fund Security**: Contract holds funds securely until conditions are met
4. **Gas Costs**: Consider transaction fees for all operations
5. **Property Verification**: Off-chain property verification required before creating escrow

### Potential Risks

- Smart contract bugs could lock funds (audit recommended)
- Agent compromise could affect fund release decisions
- Block time variations may affect expiration accuracy
- STX price volatility during escrow period

### Best Practices

- Use reputable and trusted agents
- Set reasonable expiration periods
- Verify property details off-chain before escrow creation
- Test on testnet before mainnet deployment
- Consider multi-signature requirements for high-value transactions

## Error Codes

- `u100`: Unauthorized access
- `u101`: Escrow not found
- `u102`: Escrow already exists
- `u103`: Insufficient funds
- `u104`: Escrow not in pending status
- `u105`: Escrow not funded
- `u106`: Invalid party
- `u107`: Escrow expired
- `u108`: Escrow not expired

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

ISC License - see package.json for details