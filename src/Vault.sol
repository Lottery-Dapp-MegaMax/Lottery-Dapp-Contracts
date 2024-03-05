// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PoolEvent, PoolEventType, TwabLib} from "./libraries/TwabLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MyPool} from "./MyPool.sol";
import {AbstractPool} from "./AbstractPool.sol";

contract Vault is ERC4626 {
    using TwabLib for PoolEvent[];

    mapping(address poolAddress => mapping(address owner => PoolEvent[])) public poolEvents;
    mapping(address poolAddress => uint256) private totalDeposit;

    constructor(IERC20 _asset) ERC4626(_asset) ERC20("VaultUSDT-Aave", "USDT-Aave") {}

    function deposit(uint256, address) public pure override returns (uint256) {
        revert("This function cannot be called on this contract");
    }

    function deposit(address poolAddress, uint256 assets, address receiver) public returns (uint256) {
        /// check if poolAddress is in totalDeposit keys
        totalDeposit[poolAddress] -= getCumulativeDepositInPool(poolAddress, receiver);
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }
        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);
        poolEvents[poolAddress][receiver].addPoolEvent(PoolEventType.Deposit, block.timestamp, balanceOf(receiver));
        totalDeposit[poolAddress] += getCumulativeDepositInPool(poolAddress, receiver);
        return shares;
    }

    function withdraw(uint256, address, address) public pure override returns (uint256) {
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
        poolEvents[poolAddress][owner].addPoolEvent(PoolEventType.Withdraw, block.timestamp, balanceOf(owner));
        totalDeposit[poolAddress] += getCumulativeDepositInPool(poolAddress, receiver);
        return shares;
    }

    function addNewPool(address poolAddress) public {
        require(poolAddress != address(0), "Invalid pool address");
        totalDeposit[poolAddress] = 0;
    }

    function getCumulativeDepositInPool(address poolAddress, address owner, uint256 startTime, uint256 endTime)
        public
        view
        returns (uint256)
    {
        PoolEvent[] storage poolpoolEvents = poolEvents[poolAddress][owner];
        return poolpoolEvents.getCummulativeBalanceBetween(startTime, endTime);
    }

    function getCumulativeDepositInPool(address poolAddress, address owner) public view returns (uint256) {
        AbstractPool pool = AbstractPool(poolAddress);
        return getCumulativeDepositInPool(poolAddress, owner, pool.startTime(), pool.endTime());
    }
}
