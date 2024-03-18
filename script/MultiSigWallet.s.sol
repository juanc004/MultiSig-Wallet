// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Script, console} from "forge-std/Script.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletDeploy is Script {
    function run() external {
        vm.startBroadcast(); // Start a broadcast session

        // Define the owners of the MultiSigWallet and the required confirmations
        address[] memory owners = new address[](3);
        // owners[0] = address(0x123...); // Replace with actual owner addresses
        // owners[1] = address(0x456...);
        // owners[2] = address(0x789...);
        uint required = 2;

        // Deploy the MultiSigWallet with the specified owners and required confirmations
        MultiSigWallet wallet = new MultiSigWallet(owners, required);
        console.log("MultiSigWallet deployed at:", address(wallet));

        vm.stopBroadcast(); // End the broadcast session
    }
}