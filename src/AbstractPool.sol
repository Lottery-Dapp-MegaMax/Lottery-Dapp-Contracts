// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AbstractPool is Ownable {
    uint256 private startTime;
    uint256 private endTime;
    uint256 private createdTime;

    constructor() Ownable(msg.sender) {
        createdTime = block.timestamp;
    }

    function startLottery(uint256 runningTime) public onlyOwner {
        startTime = block.timestamp;
        endTime = startTime + runningTime;
    }

    function getWinner(address[] memory _players, uint256 totalPrized) public virtual view returns (uint256[] memory) {}

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    function getEndTime() public view returns (uint256) {
        return endTime;
    }

    function getCreatedTime() public view returns (uint256) {
        return createdTime;
    }
}