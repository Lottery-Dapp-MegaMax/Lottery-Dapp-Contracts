// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./abstracts/AbstractPool.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract MyPool is AbstractPool {
    constructor(address vaultAddress, IERC20 asset_) 
        AbstractPool(vaultAddress, asset_) 
    {
        // constructor body
    }

    function getWinnerWithRandomNumber(address[] memory players, uint256[] memory shares, uint256 totalPrize, uint256 randomNumber) public override pure returns (uint256[] memory) {
        uint256[] memory winners = new uint256[](players.length);
        uint256 totalShares = 0;
        for (uint256 i = 0; i < players.length; i++) {
            totalShares += shares[i];
        }
        for (uint256 i = 0; i < players.length; i++) {
            winners[i] = (shares[i] * totalPrize) / totalShares;
        }
        return winners;
    }

}  