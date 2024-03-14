// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";


contract YieldFarmingSourceTest is Test {
    
    address yieldFarmingSource = address(0xC80aD49191113d31fe52427c01A197106ef5EB5b);
    TransparentUpgradeableProxy proxy = TransparentUpgradeableProxy(payable(yieldFarmingSource));
    address myWallet = address(0x4C4c2dCa97ff928071f4BDfdC6496ac2d6043F4F);

    function testMint() public {
        // hoax(myWallet);
        // (bool success, ) = (address(proxy)).delegatecall(abi.encodeWithSignature("mint(address,uint256)", myWallet, 1));
        // require(success, "Failed to mint");

        // hoax(myWallet);
        // (bool success2, bytes memory data) = (address(proxy)).delegatecall(abi.encodeWithSignature("balanceOf(address)", myWallet));
        // require(success2, "Failed to get balance");
        // console.logBytes(data);

    }
}