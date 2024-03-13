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
    event _Draw(address indexed poolAddress, uint256 indexed times);
    event _EarnPrize(address indexed poolAddress, address indexed receiver, uint256 indexed prize);

    EnumerableSet.AddressSet private blacklisted;
    EnumerableSet.AddressSet private poolList;

    constructor() Ownable(_msgSender()) {}

    function startLottery(address pool, uint256 runningTime) public {
        require(blacklisted.contains(pool) == false, "this pool has been blacklisted");
        require(poolList.contains(pool) == true, "this pool is not in the pool list");
        if (AbstractPool(pool).runningTime() == 0) {
            AbstractPool(pool).startLottery(runningTime);
        } else {
            require(AbstractPool(pool).balanceOf(_msgSender()) > 0, "You currently have no share in this pool");
            require(block.timestamp > AbstractPool(pool).endingTime(), "Lottery is running");
            require(AbstractPool(pool).getLastDraw() == true, "Last draw is not finished");
            AbstractPool(pool).startLottery(AbstractPool(pool).runningTime());
        }
    }

    function deposit(address pool, uint256 assets, address receiver) public returns (uint256 shares) {
        require(blacklisted.contains(pool) == false, "this pool has been blacklisted");
        require(poolList.contains(pool) == true, "this pool is not in the pool list");
        ERC20 asset = ERC20(AbstractPool(pool).asset());
        require(assets >= 5 * 10 ** asset.decimals(), "Deposit amount must be equal or greater than 5");
        shares = AbstractPool(pool).deposit(assets, receiver);
        SafeERC20.safeTransferFrom(asset, _msgSender(), pool, assets);
        emit _Deposit(pool, receiver, assets);
    }

    function totalDeposit(address pool) public view returns (uint256) {
        require(blacklisted.contains(pool) == false, "this pool has been blacklisted");
        require(poolList.contains(pool) == true, "this pool is not in the pool list");
        return AbstractPool(pool).totalDeposit();
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
        if (_msgSender() != owner()) {
            require(runningTime >= 3 days, "running time must be equal or greater than 3 days");
        }
        require(AbstractPool(pool).owner() == address(this), "pool owner is not this contract");
        AbstractPool(pool).startLottery(runningTime);
        poolList.add(pool);
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

    function getTotalCumulativeBalance(address pool) public view returns (uint256) {
        require(blacklisted.contains(pool) == false, "this pool has been blacklisted");
        require(poolList.contains(pool) == true, "this pool is not in the pool list");
        return AbstractPool(pool).getTotalCumulativeBalance();
    }

    function getWinner(address pool, uint256 totalPrize, uint256 randomNumber) public onlyOwner returns (AbstractPool.Winner[] memory) {
        require(blacklisted.contains(pool) == false, "this pool has been blacklisted");
        require(poolList.contains(pool) == true, "this pool is not in the pool list");
        if (totalPrize == 0) {
            AbstractPool(pool).setLastDraw();
            return new AbstractPool.Winner[](0);
        }
        AbstractPool.Winner[] memory winners = AbstractPool(pool).getWinner(totalPrize, randomNumber);
        emit _Draw(pool, AbstractPool(pool).numDrawBefore());
        prizeDistribution(pool, winners);
        AbstractPool(pool).setLastDraw();
        return winners;
    }

    function prizeDistribution(address pool, AbstractPool.Winner[] memory winners) internal {
        uint256 total = 0;
        for (uint256 i = 0; i < winners.length; i++) {
            total += winners[i].prize;
            AbstractPool(pool).deposit(winners[i].prize, winners[i].player);
            emit _EarnPrize(pool, winners[i].player, winners[i].prize);
        }
        SafeERC20.safeTransfer(IERC20(AbstractPool(pool).asset()), pool, total);
    }
}
