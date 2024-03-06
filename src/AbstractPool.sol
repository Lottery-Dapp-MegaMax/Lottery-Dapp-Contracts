// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AbstractPool is Ownable {
    uint256 public startTime;
    uint256 public endTime;
    uint256 public immutable createdTime;

    constructor(address vaultAddress) Ownable(vaultAddress) {
        startTime = endTime = 0;
        createdTime = block.timestamp;
    }

    function startLottery(uint256 runningTime) public onlyOwner {
        startTime = block.timestamp;
        endTime = startTime + runningTime;
    }

    function isRunning() public view returns (bool) {
        return startTime <= block.timestamp && block.timestamp <= endTime;
    }

    function getWinner(address[] memory _players, uint256 totalPrize) public virtual view returns (uint256[] memory) {}
}