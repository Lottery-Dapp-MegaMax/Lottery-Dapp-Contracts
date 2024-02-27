// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MyPool is Ownable {
    uint256 private startTime;
    uint256 private endTime;
    uint256 private immutable id;

    constructor(uint256 _id) {
        id = _id;
    } 

    function startLottery() public onlyOwner {
        startTime = block.timestamp;
    }

    function getWinner(address[] memory _players, uint256 totalPrized) public virtual view returns (uint256[]) {
        uint256[] memory prizes = new uint256[](_players.length);
        prizes[0] = totalPrized;
        return prizes;
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    function getEndTime() public view returns (uint256) {
        return endTime;
    }
}