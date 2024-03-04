// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TwabEvent, TwabEventType, TwabLib} from "./libraries/TwabLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MyPool} from "./MyPool.sol";
import {AbstractPool} from "./AbstractPool.sol";

contract Vault is ERC4626 {
    using TwabLib for TwabEvent[];

    mapping(address poolAddress => mapping(address owner => TwabEvent[])) private events;
    mapping(address poolAddress => uint256) private totalDeposit;    
    
    AbstractPool[] private activePool;

    constructor(IERC20 _asset) ERC4626(_asset) ERC20("VaultUSDT-Aave", "USDT-Aave") {
    }

    function getEvents(address poolAddress, address owner) public view returns (TwabEvent[] memory) {
        return events[poolAddress][owner];
    }

    function deposit(uint256, address) public override pure returns (uint256) {
        revert("This function cannot be called on this contract");
    }

    function deposit(address poolAddress, uint256 assets, address receiver) public returns (uint256) {
        totalDeposit[poolAddress] -= getCumulativeDepositInPool(poolAddress, receiver);
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);
        events[poolAddress][receiver].addTwabEvent(TwabEventType.Deposit, block.timestamp, balanceOf(receiver));
        totalDeposit[poolAddress] += getCumulativeDepositInPool(poolAddress, receiver);
        return shares;
    }

    function withdraw(uint256, address, address) public override pure returns (uint256) {
        revert("This function cannot be called on this contract");
    }

    function withdraw(address poolAddress, uint256 assets, address receiver, address owner) public returns (uint256) {
        totalDeposit[poolAddress] -= getCumulativeDepositInPool(poolAddress, receiver);
        require(assets > 0, "can not withdraw zero asset");
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);
        events[poolAddress][owner].addTwabEvent(TwabEventType.Withdraw, block.timestamp, balanceOf(owner));
        totalDeposit[poolAddress] += getCumulativeDepositInPool(poolAddress, receiver);
        return shares;
    }

    function createNewPool(AbstractPool newPool) public {
        activePool.push(newPool);
    }

    function getActivePools() public view returns (AbstractPool[] memory) {
        return activePool;
    }

    function getCumulativeDepositInPool(address poolAddress, address owner, uint256 startTime, uint256 endTime) public view returns (uint256) {
        TwabEvent[] storage poolEvents = events[poolAddress][owner];
        return poolEvents.getCummulativeBalanceBetween(startTime, endTime);
    }

    function getCumulativeDepositInPool(address poolAddress, address owner) public view returns (uint256) {
        AbstractPool pool = AbstractPool(poolAddress);
        return getCumulativeDepositInPool(poolAddress, owner, pool.getStartTime(), pool.getEndTime());
    }

    function getTotalDeposit(address poolAddress) public view returns (uint256) {
        return totalDeposit[poolAddress];
    }
}

