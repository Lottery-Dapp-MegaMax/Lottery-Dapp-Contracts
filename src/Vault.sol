// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TwabEvent, TwabEventType, TwabLib} from "./libraries/TwabLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Vault is ERC4626 {
    using TwabLib for TwabEvent[];

    mapping(uint256 id => mapping(address owner => TwabEvent[])) private events;

    constructor(IERC20 _asset) ERC4626(_asset) ERC20("Token", "Token") {}

    function getEvents(uint256 id, address owner) public view returns (TwabEvent[] memory) {
        return events[id][owner];
    }

    function deposit(uint256, address) public override pure returns (uint256) {
        revert("This function cannot be called on this contract");
    }

    function deposit(uint256 id, uint256 assets, address receiver) public returns (uint256) {
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        events[id][receiver].addTwabEvent(TwabEventType.Deposit, block.timestamp, balanceOf(receiver));
        return shares;
    }

    function withdraw(uint256, address, address) public override pure returns (uint256) {
        revert("This function cannot be called on this contract");
    }

    function withdraw(uint256 id, uint256 assets, address receiver, address owner) public returns (uint256) {
        require(assets > 0, "can not withdraw zero asset");
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        events[id][owner].addTwabEvent(TwabEventType.Withdraw, block.timestamp, balanceOf(owner));
        return shares;
    }
}

