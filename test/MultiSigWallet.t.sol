// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;
    address[] owners;

    function setUp() public {
        // Setup test by creating a wallet with test addresses
        owners = [address(1), address(2), address(3)];
        wallet = new MultiSigWallet(owners, 2); // Require 2 approvals
    }

    function testInitialOwners() public view {
        // Test that initial owners are set correctly
        for (uint i = 0; i < owners.length; i++) {
            assertTrue(wallet.isOwner(owners[i]));
        }
    }

    function testSubmitTransaction() public {
        // Test submitting a transaction
        vm.prank(address(1)); // Forge's vm.prank to mock msg.sender
        wallet.submit(address(0xdead), 1 ether, "");
        // Check that the transaction was submitted
        (address to,,,) = wallet.transactions(0);
        assertEq(to, address(0xdead));
    }
}
