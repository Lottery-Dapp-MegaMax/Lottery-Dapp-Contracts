// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "../src/PoolManager.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {PoolEvent, PoolEventType, TwabLib} from "../src/libraries/TwabLib.sol";
import {MyPool} from "../src/MyPool.sol";
import {AbstractPool} from "../src/abstracts/AbstractPool.sol";

contract VaultTest is Test {
    using TwabLib for PoolEvent[];

    IERC20 USDT_Contract = IERC20(0x7d682e65EFC5C13Bf4E394B8f376C48e6baE0355);
    address myWallet = address(0x4C4c2dCa97ff928071f4BDfdC6496ac2d6043F4F);
    PoolManager myPoolManager;
    MyPool myPool;

    function setUp() public {
        myPoolManager = new PoolManager();
        myPool = new MyPool(address(myPoolManager), USDT_Contract);
        myPoolManager.addNewPool(address(myPool), 300);
        console.log("USDT_Contract.balanceOf(myWallet): ", USDT_Contract.balanceOf(myWallet));
    }

    function testDeposit() public {
        // initialize
        address myPoolAddress = address(myPool);
        hoax(myWallet);
        // USDT_Contract.approve(address(myPool), 20 * (10 ** 18));
        USDT_Contract.approve(address(myPoolManager), 20 * (10 ** 18));
        hoax(myWallet);
        myPoolManager.deposit(myPoolAddress, 20 * (10 ** 18), myWallet);

        // test
        console.log("USDT balance: ", USDT_Contract.balanceOf(myWallet));
        console.log("Share balances in vault: ", myPool.balanceOf(myWallet));
        console.log("Started time: ", myPool.startedTime());
        skip(100);
        skip(50);
        console.log("Current time: ", block.timestamp);
        // PoolEvent[] memory events = myPoolManager.getEvents(myPoolAddress, myWallet);
        // for (uint256 i = 0; i < events.length; i++) {
        //     console.log("Event: ", events[i].eventType, events[i].timestamp, events[i].value);
        // }
        console.log("Share balances in vault for myPool: ", myPool.getCurrentCumulativeBalance(myWallet));
        hoax(myWallet);
        myPoolManager.withdraw(myPoolAddress, 20 ether, myWallet, myWallet);
        skip(50);
        console.log("Share balances in vault for myPool: ", myPool.getCurrentCumulativeBalance(myWallet));
        assertEq(USDT_Contract.balanceOf(myWallet), 99999999999999995200);
    }

    function testActivePool() public {
        myPool = new MyPool(address(myPoolManager), USDT_Contract);
        myPoolManager.blacklist(address(myPool));
        address[] memory blacklistedPool = myPoolManager.getBlacklisted();
        console.log("Blacklisted pool: ", blacklistedPool.length);
        for (uint256 i = 0; i < blacklistedPool.length; i++) {
            console.log("Blacklisted pool: ", blacklistedPool[i]);
        }
    }

    function testDraw() public {
        hoax(myWallet);
        USDT_Contract.transfer(address(this), 20 * (10 ** 18));
        console.log(USDT_Contract.balanceOf(address(this)));
        hoax(myWallet);
        USDT_Contract.transfer(address(myPoolManager), 10 * (10 ** 18));

        USDT_Contract.approve(address(myPoolManager), 20 * (10 ** 18));
        myPoolManager.deposit(address(myPool), 10 * (10 ** 18), address(this));

        skip(400);
        console.log("balance: ", myPool.getCurrentCumulativeBalance(address(this)));
        console.log("shares: ", myPool.balanceOf(address(this)));
        console.log("max withdraw: ", myPool.maxWithdraw(address(this)));
        console.log(USDT_Contract.balanceOf(address(myPool)));

        AbstractPool.Winner[] memory winners = myPoolManager.getWinner(address(myPool), 10 * (10 ** 18), 5);
        for (uint256 i = 0; i < winners.length; i++) {
            console.log("Winner: ", winners[i].player, winners[i].prize);
        }
        console.log("shares: ", myPool.balanceOf(address(this)));
        console.log("max withdraw: ", myPool.maxWithdraw(address(this)));
        console.log(USDT_Contract.balanceOf(address(myPool)));
    }
}