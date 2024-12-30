# Token Wallet Contract

A basic Ethereum wallet smart contract demonstrating ETH management, events, and multi-user support.

## Project Overview

### Features
- Receive and store ETH
- Withdraw funds
- Check balances
- Transfer between users
- Event tracking for transactions
- Comprehensive test coverage

### Contract Interface
```solidity
interface ITokenWallet {
    function getBalance(address user) external view returns (uint256);
    function withdraw(uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Transferred(address indexed from, address indexed to, uint256 amount);
}
```

### Development Tools
- Foundry (for testing and deployment)
- Solidity ^0.8.19
- MetaMask (for testing)

## Project Tasks

### 1. Create function to receive ETH
- [x] Set up basic contract structure
- [x] Implement receive() function
- [x] Implement fallback() function
- [x] Create balance mapping
- [x] Emit deposit events

### 2. Implement withdrawal function
- [ ] Create withdraw function
- [ ] Add balance checks
- [ ] Implement reentrancy protection
- [ ] Add withdrawal event emission
- [ ] Test for edge cases

### 3. Add balance checking
- [ ] Create balance view function
- [ ] Add total balance tracking
- [ ] Implement balance validation
- [ ] Add balance query tests

### 4. Implement transfer between users
- [ ] Create transfer function
- [ ] Add balance validations
- [ ] Implement transfer event
- [ ] Test transfer scenarios
- [ ] Add protection against common vulnerabilities

### 5. Write comprehensive tests
- [ ] Test deposit functionality
- [ ] Test withdrawal scenarios
- [ ] Test balance checking
- [ ] Test transfer functionality
- [ ] Add fuzz testing
- [ ] Test edge cases and reverts
- [ ] Test event emissions

### 6. Deploy to testnet
- [ ] Create deployment script
- [ ] Set up testnet configuration
- [ ] Deploy to Sepolia/Goerli
- [ ] Verify contract on Etherscan
- [ ] Test live contract functionality

## Local Development

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/downloads)

### Setup
1. Clone the repository
```bash
git clone git@github.com:baasbank/solidity-eth-wallet.git
cd token-wallet
```

2. Install dependencies
```bash
forge install
```

### Testing
Run all tests:
```bash
forge test
```

Run a specific test with verbosity:
```bash
forge test --match-test testDeposit -vv
```

### Local Deployment
1. Start local node:
```bash
anvil
```

2. Deploy contract:
```bash
forge script script/Deploy.s.sol:DeployTokenWallet --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY --broadcast
```

### Security Considerations
- Implement checks-effects-interactions pattern
- Add reentrancy guards
- Validate all inputs
- Use SafeMath for older Solidity versions
- Consider gas limitations
- Add emergency withdrawal functionality

## Contributing
Feel free to submit issues and enhancement requests!
