// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AbstractPool is Ownable {
    uint256 public startTime;
    uint256 public endTime;
    uint256 public immutable createdTime;

    constructor() Ownable(msg.sender) {
        createdTime = block.timestamp;
    }

    function startLottery(uint256 runningTime) public onlyOwner {
        startTime = block.timestamp;
        endTime = startTime + runningTime;
    }

    function getWinner(address[] memory _players, uint256 totalPrize) public virtual view returns (uint256[] memory) {}
}