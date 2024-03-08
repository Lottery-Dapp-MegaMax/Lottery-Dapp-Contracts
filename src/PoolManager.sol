// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AbstractPool} from "./abstracts/AbstractPool.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";


contract PoolManager is Ownable{
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event Deposit(address poolAddress, address sender, address receiver, uint256 assets, uint256 shares);
    event Withdraw(address poolAddress, address sender, address receiver, address owner, uint256 assets, uint256 shares);
    event AddNewPool(address poolAddress);

    EnumerableSet.AddressSet private blacklisted;
    EnumerableSet.AddressSet private poolList;

    constructor() Ownable(_msgSender()) {}

    function deposit(address pool, uint256 assets, address receiver) public returns (uint256 shares) {
        require(blacklisted.contains(pool) == false, "this pool has been blacklisted");
        require(poolList.contains(pool) == true, "this pool is not in the pool list");
        shares = AbstractPool(pool).deposit(assets, receiver);
        emit Deposit(pool, _msgSender(), receiver, assets, shares);
    }

    function withdraw(address pool, uint256 assets, address receiver, address owner) public returns (uint256 shares) {
        require(poolList.contains(pool) == true, "this pool is not in the pool list");
        shares = AbstractPool(pool).withdraw(assets, receiver, owner);
        emit Withdraw(pool, _msgSender(), receiver, owner, assets, shares);
    }

    function addNewPool(address pool, uint256 runningTime) public {
        require(blacklisted.contains(pool) == false, "this pool has been blacklisted");
        require(pool != address(0), "pool address is zero");
        require(poolList.contains(pool) == false, "this pool is already in pool list");
        require(runningTime >= 3 days);
        AbstractPool(pool).startLottery(runningTime);
        poolList.add(pool);
        emit AddNewPool(pool);
    }

    function removePool(address pool) public onlyOwner {
        poolList.remove(pool);
    }

    function blacklist(address pool) public onlyOwner {
        blacklisted.add(pool);
    }

    function getCumulativeBalanceInPool(address pool, address owner, uint256 startTime, uint256 endTime) public view returns (uint256) {
        require(blacklisted.contains(pool) == false, "this pool has been blacklisted");
        require(poolList.contains(pool) == true, "this pool is not in the pool list");
        return AbstractPool(pool).getCumulativeBalanceBetween(owner, startTime, endTime);
    }

    function getCurrentCumulativeBalanceInPool(address pool, address owner) public view returns (uint256) {
        require(blacklisted.contains(pool) == false, "this pool has been blacklisted");
        require(poolList.contains(pool) == true, "this pool is not in the pool list");
        return AbstractPool(pool).getCurrentCumulativeBalance(owner);
    }

    function getActivePools() public view returns (address[] memory activePools) {
        uint256 numActivePools = 0;
        for (uint256 i = 0; i < poolList.length(); i ++) {
            if (blacklisted.contains(poolList.at(i)) == false) {
                ++ numActivePools;
            }
        }
        activePools = new address[](numActivePools);
        numActivePools = 0;
        for (uint256 i = 0; i < poolList.length(); i ++) {
            if (blacklisted.contains(poolList.at(i)) == false) {
                activePools[numActivePools] = poolList.at(i);
                ++ numActivePools;
            }
        }
    }

    function getDepositorsInPool(address pool, uint256 startTime, uint256 endTime) public view returns (address[] memory depositors) {
        require(blacklisted.contains(pool) == false, "this pool has been blacklisted");
        require(poolList.contains(pool) == true, "this pool is not in the pool list");
        uint256 numDepositors = 0;
        for (uint256 i = 0; i < AbstractPool(pool).getDepositors().length; i ++) {
            address currentDepositor = AbstractPool(pool).getDepositors()[i];
            if (getCumulativeBalanceInPool(pool, currentDepositor, startTime, endTime) == 0) {
                continue;
            }
            ++ numDepositors;
        }
        depositors = new address[](numDepositors);
        numDepositors = 0;
        for (uint256 i = 0; i < AbstractPool(pool).getDepositors().length; i ++) {
            address currentDepositor = AbstractPool(pool).getDepositors()[i];
            if (getCumulativeBalanceInPool(pool, currentDepositor, startTime, endTime) == 0) {
                continue;
            }
            depositors[numDepositors] = currentDepositor;
            ++ numDepositors;
        }
    }

    function getTotalSharesInPool(address poolAddress, uint256 startTime, uint256 endTime) public view returns (uint256 totalShares) {
        address[] memory depositors = getDepositorsInPool(poolAddress, startTime, endTime);
        for (uint256 i = 0; i < depositors.length; ++ i) {
            totalShares += getCumulativeBalanceInPool(poolAddress, depositors[i], startTime, endTime);
        }
    }

    function getBlacklisted() public view returns (address[] memory) {
        return blacklisted.values();
    }
}
