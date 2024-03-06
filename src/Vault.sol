// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PoolEvent, PoolEventType, TwabLib} from "./libraries/TwabLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MyPool} from "./MyPool.sol";
import {AbstractPool} from "./AbstractPool.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Vault is ERC4626 {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event Deposit(address poolAddress, address sender, address receiver, uint256 assets, uint256 shares);
    event Withdraw(address poolAddress, address sender, address receiver, address owner, uint256 assets, uint256 shares);
    event AddNewPool(address poolAddress);

    using TwabLib for PoolEvent[];

    mapping(address poolAddress => mapping(address owner => PoolEvent[])) public poolEvents;
    mapping(address poolAddress => EnumerableSet.AddressSet depositors) private depositorsInPool;
    mapping(address poolAddress => uint256 lastDrawTime) public lastDrawTime;
    EnumerableSet.AddressSet private activePools;
    EnumerableSet.AddressSet private blacklistPools;
    address public manager;

    constructor(IERC20 _asset) ERC4626(_asset) ERC20("VaultUSDT-Aave", "USDT-Aave") {
        manager = _msgSender();
    }

    function deposit(uint256, address) public pure override returns (uint256) {
        revert("This function cannot be called on this contract");
    }

    function deposit(address poolAddress, uint256 assets, address receiver) public returns (uint256) {
        require(blacklistPools.contains(poolAddress) == false, "this pool address is troll");
        /// check if poolAddress is in totalDeposit keys
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }
        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);
        poolEvents[poolAddress][receiver].addPoolEvent(PoolEventType.Deposit, block.timestamp, balanceOf(receiver));
        emit Deposit(poolAddress, _msgSender(), receiver, assets, shares);
        depositorsInPool[poolAddress].add(receiver);
        return shares;
    }

    function withdraw(uint256, address, address) public pure override returns (uint256) {
        revert("This function cannot be called on this contract");
    }

    function withdraw(address poolAddress, uint256 assets, address receiver, address owner) public returns (uint256) {
        require(blacklistPools.contains(poolAddress) == false, "this pool address is troll");
        require(assets > 0, "can not withdraw zero asset");
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);
        poolEvents[poolAddress][owner].addPoolEvent(PoolEventType.Withdraw, block.timestamp, balanceOf(owner));
        emit Withdraw(poolAddress, _msgSender(), receiver, owner, assets, shares);
        return shares;
    }

    function addNewPool(address poolAddress, uint256 runningTime) public {
        require(blacklistPools.contains(poolAddress) == false, "this pool address is troll");
        require(poolAddress != address(0), "Invalid pool address");
        require(activePools.contains(poolAddress) == false, "already in vault");
        require(runningTime >= 3 days);
        AbstractPool apool = AbstractPool(poolAddress);
        apool.startLottery(runningTime);
        activePools.add(poolAddress);
        emit AddNewPool(poolAddress);
    }

    function removePool(address poolAddress) public {
        require(_msgSender() == manager);
        blacklistPools.add(poolAddress);
    }

    function getCumulativeDepositInPool(address poolAddress, address owner, uint256 startTime, uint256 endTime)
        public
        view
        returns (uint256)
    {
        require(blacklistPools.contains(poolAddress) == false, "this pool address is troll");
        PoolEvent[] storage poolpoolEvents = poolEvents[poolAddress][owner];
        return poolpoolEvents.getCummulativeBalanceBetween(startTime, endTime);
    }

    function getCumulativeDepositInPool(address poolAddress, address owner) public view returns (uint256) {
        require(blacklistPools.contains(poolAddress) == false, "this pool address is troll");
        AbstractPool pool = AbstractPool(poolAddress);
        return getCumulativeDepositInPool(poolAddress, owner, pool.getCurrentStartTime(), pool.getCurrentEndTime());
    }

    function getListActivePools() public view returns (address[] memory) {
        uint256 poolSize = activePools.length();
        address[] memory addressActivePools = new address[](poolSize);
        for (uint256 i = 0; i < activePools.length(); i ++) {
            if (blacklistPools.contains(activePools.at(i)) == false) {
                addressActivePools[i] = activePools.at(i);
            }
        }
        return addressActivePools;
    }

    function getListDepositorsInPool(address poolAddress, uint256 startTime, uint256 endTime) public view returns (address[] memory) {
        require(blacklistPools.contains(poolAddress) == false, "this pool address is troll");
        uint256 Count = 0;
        for (uint256 i = 0; i < depositorsInPool[poolAddress].length(); i ++) {
            address currentDepositor = depositorsInPool[poolAddress].at(i);
            if (getCumulativeDepositInPool(poolAddress, currentDepositor, startTime, endTime) == 0) {
                continue;
            }
            ++ Count;
        }
        address[] memory addressDepositorsInPool = new address[](Count);
        Count = 0;
        for (uint256 i = 0; i < depositorsInPool[poolAddress].length(); i ++) {
            address currentDepositor = depositorsInPool[poolAddress].at(i);
            if (getCumulativeDepositInPool(poolAddress, currentDepositor) == 0) {
                continue;
            }
            addressDepositorsInPool[Count ++] = currentDepositor;
        }
        return addressDepositorsInPool;
    }

    function getTotalSharesInPool(address poolAddress, uint256 startTime, uint256 endTime) public view returns (uint256) {
        address[] memory listDepositors = getListDepositorsInPool(poolAddress, startTime, endTime);
        uint256 totalShares = 0;
        for (uint256 i = 0; i < listDepositors.length; ++ i) {
            totalShares += getCumulativeDepositInPool(poolAddress, listDepositors[i], startTime, endTime);
        }
        return totalShares;
    }
}
