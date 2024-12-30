// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenWallet {
    bool private locked;
    bool public paused;
    address public owner;
    mapping(address => uint256) public balances;
    uint256 public totalBalance;

    event Deposit(address indexed user, uint256 amount, string method);
    event Withdrawal(address indexed user, uint256 amount, string method);
    event Transfer(address indexed from, address indexed to, uint256 amount, string method);

    error Paused();
    error NotOwner();
    error TransferFailed();
    error InvalidRecipient();

    constructor() {
        owner = msg.sender;
    }

    modifier nonReentrant() {
        require(!locked, "ReentrancyGuard:Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        emit Deposit(msg.sender, msg.value, "receive");
    }

    fallback() external payable {
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        emit Deposit(msg.sender, msg.value, "fallback");
    }

    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }

    function withdraw(uint256 amount) public nonReentrant whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Contract has insufficient balance");
        
        balances[msg.sender] -= amount;
        totalBalance -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();
        
        emit Withdrawal(msg.sender, amount, "withdraw");
    }

    function transfer(address to, uint256 amount) public nonReentrant whenNotPaused {
        if (to == address(0) || to == address(this)) revert InvalidRecipient();
        
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(amount > 0, "Amount must be greater than 0");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount, "transfer");
        
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    function pause() external onlyOwner {
        paused = true;
    }
    
    function unpause() external onlyOwner {
        paused = false;
    }
    
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        // Store old values for debugging
        uint256 oldTotalBalance = totalBalance;
        
        // Reset total balance before transfer
        totalBalance = 0;
        
        // Try transfer with more specific error handling
        (bool success, ) = payable(owner).call{value: balance}("");
        if (!success) {
            // Restore state if transfer fails
            totalBalance = oldTotalBalance;
            revert TransferFailed();
        }
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner address");
        owner = newOwner;
    }
}
