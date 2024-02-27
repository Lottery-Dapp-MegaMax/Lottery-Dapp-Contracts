// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MyVault.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract MyVaultDeployer is Ownable {
    constructor() Ownable(address(msg.sender)) {}

    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private activeAssets;

    MyVault[] public activeVaults;

    function deployNewVault(IERC20 _asset) public onlyOwner() {
        require(!EnumerableSet.contains(activeAssets, address(_asset)), "Asset already has a vault");
        MyVault newVault = new MyVault(_asset);
        activeVaults.push(newVault);
        EnumerableSet.add(activeAssets, address(_asset));
    }
}