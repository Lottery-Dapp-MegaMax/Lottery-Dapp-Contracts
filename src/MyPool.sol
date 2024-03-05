// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AbstractPool.sol";

contract MyPool is AbstractPool {
    function getWinner(address[] memory _players, uint256 totalPrized) public override pure returns (uint256[] memory) {
        uint256[] memory prizes = new uint256[](_players.length);
        prizes[0] = totalPrized;
        return prizes;
    }
}  