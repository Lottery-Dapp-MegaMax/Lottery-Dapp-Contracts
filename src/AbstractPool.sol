// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract AbstractPool is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public period;
    uint256 public startedTime;

    constructor(address vaultAddress) Ownable(vaultAddress) {
    }

    function startLottery(uint256 _period) public onlyOwner {
        startedTime = block.timestamp;
        period = _period;
    }

    function drawTimes() public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 times = Math.ceilDiv(currentTime - startedTime, period);
        return times;
    }

    function getStartTime(uint256 _drawTime) public view returns (uint256) {
        require(_drawTime > 0, "drawTime must be positive");
        require(period != 0, "Lottery has not started yet");
        return startedTime + (_drawTime - 1) * period;
    }

    function getEndTime(uint256 _drawTime) public view returns (uint256) {
        require(_drawTime > 0, "drawTime must be positive");
        require(period != 0, "Lottery has not started yet");
        return getStartTime(_drawTime) + period;
    }

    function getCurrentStartTime() public view returns (uint256) {
        require(period != 0, "Lottery has not started yet");
        return getStartTime(drawTimes());
    }

    function getCurrentEndTime() public view returns (uint256) {
        require(period != 0, "Lottery has not started yet");
        return getCurrentStartTime() + period;
    }

    function getWinner(address[] memory _players, uint256 totalPrize) public virtual view returns (uint256[] memory) {}
}