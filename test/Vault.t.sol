// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "../src/Vault.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {PoolEvent, PoolEventType, TwabLib} from "../src/libraries/TwabLib.sol";

contract VaultTest is Test {
    using TwabLib for PoolEvent[];

    IERC20 USDT_Contract = IERC20(0x7d682e65EFC5C13Bf4E394B8f376C48e6baE0355);
    address myWallet = address(0x4C4c2dCa97ff928071f4BDfdC6496ac2d6043F4F);
    Vault vault;
    MyPool myPool;

    function setUp() public {
        vault = new Vault(USDT_Contract);
        myPool = new MyPool();
        vault.addNewPool(address(myPool));
        myPool.startLottery(100);
        console.log("USDT_Contract.balanceOf(myWallet): ", USDT_Contract.balanceOf(myWallet));
    }

    function testDeposit() public {
        // initialize
        address myPoolAddress = address(myPool);
        hoax(myWallet);
        USDT_Contract.approve(address(vault), 20 * (10 ** 18));
        hoax(myWallet);
        vault.deposit(myPoolAddress, 20 * (10 ** 18), myWallet);

        // test
        console.log("USDT balance: ", USDT_Contract.balanceOf(myWallet));
        console.log("Share balances in vault: ", vault.balanceOf(myWallet));
        console.log("Start time: ", myPool.startTime());
        console.log("End time: ", myPool.endTime());
        console.log("Created time: ", myPool.createdTime());
        skip(50);
        console.log("Current time: ", block.timestamp);
        // PoolEvent[] memory events = vault.getEvents(myPoolAddress, myWallet);
        // for (uint256 i = 0; i < events.length; i++) {
        //     console.log("Event: ", events[i].eventType, events[i].timestamp, events[i].value);
        // }
        console.log("Share balances in vault for myPool: ", vault.getCumulativeDepositInPool(myPoolAddress, myWallet));
        hoax(myWallet);
        vault.withdraw(myPoolAddress, 10 * (10 ** 18), myWallet, myWallet);
        skip(50);
        console.log("Share balances in vault for myPool: ", vault.getCumulativeDepositInPool(myPoolAddress, myWallet));
    }
}