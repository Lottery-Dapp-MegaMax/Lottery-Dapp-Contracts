// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {PoolEvent, PoolEventType, TwabLib} from "../libraries/TwabLib.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

abstract contract AbstractPool is Ownable, ERC4626 {
    using EnumerableSet for EnumerableSet.AddressSet;
    using TwabLib for PoolEvent[];

    uint256 public period;
    uint256 public startedTime;
    mapping(address owner => PoolEvent[]) public poolEvents;
    EnumerableSet.AddressSet private depositors;
    uint256 public lastDrawTime;

    constructor(address poolManager, IERC20 asset_) Ownable(poolManager) ERC4626(asset_) {
    }

    function startLottery(uint256 _period) public onlyOwner {
        startedTime = block.timestamp;
        period = _period;
    }

    function drawTimes() public view returns (uint256 times) {
        uint256 currentTime = block.timestamp;
        times = Math.ceilDiv(currentTime - startedTime, period);
    }

    function getStartTime(uint256 drawTime) public view returns (uint256) {
        require(drawTime > 0, "drawTime must be positive");
        require(period != 0, "Lottery has not started yet");
        return startedTime + (drawTime - 1) * period;
    }

    function getEndTime(uint256 drawTime) public view returns (uint256) {
        require(drawTime > 0, "drawTime must be positive");
        require(period != 0, "Lottery has not started yet");
        return startedTime + drawTime * period;
    }

    function getCurrentStartTime() public view returns (uint256) {
        require(period != 0, "Lottery has not started yet");
        return getStartTime(drawTimes());
    }

    function getCurrentEndTime() public view returns (uint256) {
        require(period != 0, "Lottery has not started yet");
        return getCurrentStartTime() + period;
    }

    function getWinner(address[] memory players, uint256 totalPrize) public virtual view returns (uint256[] memory) {}

    function deposit(uint256 assets, address receiver) public override onlyOwner returns (uint256 shares) {
        shares = super.deposit(assets, receiver);
        poolEvents[receiver].addPoolEvent(PoolEventType.Deposit, block.timestamp, balanceOf(receiver));
        depositors.add(receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override onlyOwner returns (uint256 shares) {
        shares = super.withdraw(assets, receiver, owner);
        poolEvents[receiver].addPoolEvent(PoolEventType.Withdraw, block.timestamp, balanceOf(receiver));
    }

    function getCumulativeBalanceBetween(address owner, uint256 startTime, uint256 endTime) public view returns (uint256) {
        return poolEvents[owner].getCummulativeBalanceBetween(startTime, endTime);
    }

    function getCurrentCumulativeBalance(address owner) public view returns (uint256) {
        return poolEvents[owner].getCummulativeBalanceBetween(getCurrentStartTime(), getCurrentEndTime());
    }

    function getDepositors() public view returns (address[] memory) {
        return depositors.values();
    }
}