// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {TokenWallet} from "../src/TokenWallet.sol";

contract TokenWalletTest is Test {
    TokenWallet public wallet;
    address public alice;
    address public bob;
    uint256 public constant INITIAL_BALANCE = 100 ether;

    event Deposit(address indexed user, uint256 amount, string method);
    event Withdrawal(address indexed user, uint256 amount, string method);
    event Transfer(address indexed from, address indexed to, uint256 amount, string method);
    function setUp() public {
        wallet = new TokenWallet();
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        
        // Fund test accounts
        vm.deal(alice, INITIAL_BALANCE);
        vm.deal(bob, INITIAL_BALANCE);
    }

    /// Task 1: Create function to receive ETH
    function test_ReceiveEth() public {
        uint256 depositAmount = 1 ether;
        
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Deposit(alice, depositAmount, "receive");
        (bool success,) = address(wallet).call{value: depositAmount}("");
        
        assertTrue(success, "ETH transfer failed");
        assertEq(wallet.getBalance(alice), depositAmount);
    }

    function test_FallbackEth() public {
        uint256 depositAmount = 1 ether;
        
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Deposit(alice, depositAmount, "fallback");
        (bool success,) = address(wallet).call{value: depositAmount}(hex"1234");
        
        assertTrue(success, "ETH transfer with data failed");
        assertEq(wallet.getBalance(alice), depositAmount);
    }

    // Task 2: Implement withdrawal function
    function test_WithdrawEth() public {
        // First deposit some ETH
        vm.prank(alice);
        (bool success,) = address(wallet).call{value: 1 ether}("");
        assertTrue(success, "Deposit failed");

        // Then withdraw
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Withdrawal(alice, 0.5 ether, "withdraw");
        
        uint256 balanceBefore = alice.balance;
        
        wallet.withdraw(0.5 ether);
        
        assertEq(alice.balance, balanceBefore + 0.5 ether);
        assertEq(wallet.getBalance(alice), 0.5 ether);
    }

    function test_WithdrawFail_InsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert("Insufficient balance");
        wallet.withdraw(1 ether);
    }

    // Test withdrawing zero amount
    function test_WithdrawFail_ZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert("Amount must be greater than 0");
        wallet.withdraw(0);
    }

    // Test withdrawing exact balance
    function test_WithdrawExactBalance() public {
        // Setup: Deposit 1 ETH
        vm.prank(alice);
        (bool success,) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);

        // Withdraw entire balance
        vm.prank(alice);
        wallet.withdraw(1 ether);

        assertEq(wallet.getBalance(alice), 0);
    }

    // Test multiple withdrawals
    function test_MultipleWithdrawals() public {
        // Setup: Deposit 1 ETH
        vm.prank(alice);
        (bool success,) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);

        // First withdrawal
        vm.prank(alice);
        wallet.withdraw(0.3 ether);
        assertEq(wallet.getBalance(alice), 0.7 ether);

        // Second withdrawal
        vm.prank(alice);
        wallet.withdraw(0.4 ether);
        assertEq(wallet.getBalance(alice), 0.3 ether);
    }

    // Test contract has enough ETH
    function test_WithdrawFail_ContractBalance() public {
        // Setup: Deposit 1 ETH
        vm.prank(alice);
        (bool success,) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);

        // Drain contract balance (simulating an error)
        vm.deal(address(wallet), 0);

        // Try to withdraw
        vm.prank(alice);
        vm.expectRevert();
        wallet.withdraw(1 ether);
    }

    // Test withdrawal limits
    function test_WithdrawFail_MaxAmount() public {
        // Try to withdraw max uint256
        vm.prank(alice);
        vm.expectRevert("Insufficient balance");
        wallet.withdraw(type(uint256).max);
    }

    // Fuzz testing
    function testFuzz_Withdraw(uint96 depositAmount, uint96 withdrawAmount) public {
        // Bound the values to reasonable ranges
        vm.assume(depositAmount > 0);
        vm.assume(withdrawAmount > 0);
        vm.assume(withdrawAmount <= depositAmount);
        
        // Setup
        vm.deal(alice, depositAmount);
        
        // Deposit
        vm.prank(alice);
        (bool success,) = address(wallet).call{value: depositAmount}("");
        assertTrue(success);
        
        // Withdraw
        vm.prank(alice);
        wallet.withdraw(withdrawAmount);
        
        // Assert
        assertEq(wallet.getBalance(alice), depositAmount - withdrawAmount);
    }

    /// Task 3: Add balance checking
    function test_GetBalance() public {
        assertEq(wallet.getBalance(alice), 0);

        vm.prank(alice);
        (bool success,) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);

        assertEq(wallet.getBalance(alice), 1 ether);
    }

    /// Task 4: Implement transfer between users
    function test_TransferBetweenUsers() public {
        // First deposit
        vm.prank(alice);
        (bool success,) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);

        // Then transfer to Bob
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, bob, 0.5 ether, "transfer");
        wallet.transfer(bob, 0.5 ether);

        assertEq(wallet.getBalance(alice), 0.5 ether);
        assertEq(wallet.getBalance(bob), 0.5 ether);
    }

    function test_TransferFail_InsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert("Insufficient balance");
        wallet.transfer(bob, 1 ether);
    }

    function test_TransferFail_InvalidRecipient() public {
        vm.prank(alice);
        vm.expectRevert(TokenWallet.InvalidRecipient.selector);
        wallet.transfer(address(0), 1 ether);
    }

    /// Fuzz Testing
    function testFuzz_Deposit(uint96 amount) public {
        vm.assume(amount > 0);
        vm.deal(alice, uint256(amount));

        vm.prank(alice);
        (bool success,) = address(wallet).call{value: amount}("");
        
        assertTrue(success);
        assertEq(wallet.getBalance(alice), amount);
    }

    function testFuzz_WithdrawPartial(uint96 depositAmount, uint96 withdrawAmount) public {
        vm.assume(depositAmount > 0);
        vm.assume(withdrawAmount > 0);
        vm.assume(withdrawAmount <= depositAmount);
        vm.deal(alice, uint256(depositAmount));

        // Deposit
        vm.prank(alice);
        (bool success,) = address(wallet).call{value: depositAmount}("");
        assertTrue(success);

        // Withdraw
        vm.prank(alice);
        wallet.withdraw(withdrawAmount);

        assertEq(wallet.getBalance(alice), depositAmount - withdrawAmount);
    }

    function test_PauseContract() public {
        // Pause contract
        vm.prank(wallet.owner());
        wallet.pause();
        
        // Try to withdraw
        vm.prank(alice);
        vm.expectRevert(TokenWallet.Paused.selector);
        wallet.withdraw(1 ether);
    }

    function test_InvalidRecipient() public {
        // Setup
        vm.prank(alice);
        (bool success,) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);
        
        // Try to transfer to zero address
        vm.prank(alice);
        vm.expectRevert(TokenWallet.InvalidRecipient.selector);
        wallet.transfer(address(0), 0.5 ether);
        
        // Try to transfer to contract itself
        vm.prank(alice);
        vm.expectRevert(TokenWallet.InvalidRecipient.selector);
        wallet.transfer(address(wallet), 0.5 ether);
    }

    function test_EmergencyWithdraw() public {
        // First make the owner a proper EOA address
        address payable newOwner = payable(makeAddr("owner"));
        
        // Transfer ownership to our test address
        vm.prank(wallet.owner());
        wallet.transferOwnership(newOwner);
        
        // Setup: Fund contract properly through deposit
        vm.deal(alice, 1 ether);
        
        vm.prank(alice);
        (bool depositSuccess,) = address(wallet).call{value: 1 ether}("");
        require(depositSuccess, "Deposit failed");
        
        // Try emergency withdraw with our test owner
        vm.prank(newOwner);
        wallet.emergencyWithdraw();
        
        // Verify the transfer worked
        assertEq(address(wallet).balance, 0);
        assertEq(wallet.totalBalance(), 0);
        assertEq(newOwner.balance, 1 ether);
    }
} 
