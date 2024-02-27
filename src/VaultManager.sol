// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MultiVault is ERC1155 {
    constructor() ERC1155("https://token-cdn-domain/{id}.json") {
        _mint(msg.sender, 0, 100, "");
    }
}