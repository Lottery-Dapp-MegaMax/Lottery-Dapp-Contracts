// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Vault} from "src/Vault.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {MyPool} from "src/MyPool.sol";

contract DeployScript is Script {
    IERC20 conflux_testnet_usdt_contract;
    Vault myVault;

    function setUp() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        conflux_testnet_usdt_contract = IERC20(0x7d682e65EFC5C13Bf4E394B8f376C48e6baE0355);
        myVault = new Vault(conflux_testnet_usdt_contract);
        console.log("Vault created at: %s", address(myVault));
        MyPool myPool = new MyPool(address(myVault));
        myVault.addNewPool(address(myPool), 120);
        vm.stopBroadcast();
    }

    function run() public {
    }
}
