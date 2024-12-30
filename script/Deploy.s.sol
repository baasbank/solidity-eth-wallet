// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import "../src/TokenWallet.sol";

contract DeployTokenWallet is Script {
    function run() external returns (TokenWallet) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console2.log("Deploying TokenWallet to Sepolia...");
        console2.log("Deployer:", vm.addr(deployerPrivateKey));
        
        vm.startBroadcast(deployerPrivateKey);
        
        TokenWallet tokenWallet = new TokenWallet();
        
        console2.log("TokenWallet deployed to:", address(tokenWallet));
        
        vm.stopBroadcast();
        return tokenWallet;
    }
}