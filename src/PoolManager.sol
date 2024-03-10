// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AbstractPool} from "./abstracts/AbstractPool.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract PoolManager is Ownable{
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event _Deposit(address indexed poolAddress, address indexed receiver, uint256 indexed assets);
    event _Withdraw(address indexed poolAddress, address indexed receiver, uint256 indexed assets);
    event AddNewPool(address indexed poolAddress);

    EnumerableSet.AddressSet private blacklisted;
    EnumerableSet.AddressSet private poolList;

    constructor() Ownable(_msgSender()) {}

    function deposit(address pool, uint256 assets, address receiver) public returns (uint256 shares) {
        require(blacklisted.contains(pool) == false, "this pool has been blacklisted");
        require(poolList.contains(pool) == true, "this pool is not in the pool list");
        shares = AbstractPool(pool).deposit(assets, receiver);
        IERC20 asset = IERC20(AbstractPool(pool).asset());
        SafeERC20.safeTransferFrom(asset, _msgSender(), pool, assets);
        emit _Deposit(pool, receiver, assets);
    }

    function withdraw(address pool, uint256 assets, address receiver, address owner) public returns (uint256 shares) {
        require(poolList.contains(pool) == true, "this pool is not in the pool list");
        require(_msgSender() == owner, "Only owner should withdraw");
        shares = AbstractPool(pool).withdraw(assets, receiver, owner);
        IERC20 asset = IERC20(AbstractPool(pool).asset());
        SafeERC20.safeTransferFrom(asset, pool, receiver, assets);
        emit _Withdraw(pool, receiver, assets);
    }

    function addNewPool(address pool, uint256 runningTime) public {
        require(blacklisted.contains(pool) == false, "this pool has been blacklisted");
        require(pool != address(0), "pool address is zero");
        require(poolList.contains(pool) == false, "this pool is already in pool list");
        // require(runningTime >= 3 days);
        require(AbstractPool(pool).owner() == address(this), "pool owner is not this contract");
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

    function getDepositorsInPool(address pool, uint256 startTime, uint256 endTime) public view returns (address[] memory) {
        require(blacklisted.contains(pool) == false, "this pool has been blacklisted");
        require(poolList.contains(pool) == true, "this pool is not in the pool list");
        return AbstractPool(pool).getDepositors(startTime, endTime);
    }

        function getDepositorsInPool(address pool) public view returns (address[] memory) {
        require(blacklisted.contains(pool) == false, "this pool has been blacklisted");
        require(poolList.contains(pool) == true, "this pool is not in the pool list");
        return AbstractPool(pool).getDepositors();
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

    function getWinner(address pool, uint256 totalPrize, uint256 randomNumber) public onlyOwner returns (uint256[] memory) {
        require(blacklisted.contains(pool) == false, "this pool has been blacklisted");
        require(poolList.contains(pool) == true, "this pool is not in the pool list");
        uint256[] memory prizes = AbstractPool(pool).getWinner(totalPrize, randomNumber);
        AbstractPool(pool).setLastDraw();
        return prizes;
    }
}
