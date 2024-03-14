// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PoolManager} from "src/PoolManager.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {MyPool} from "src/MyPool.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DeployScript is Script {
    IERC20 conflux_testnet_usdt_contract;
    PoolManager myPoolManager;

    function setUp() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        conflux_testnet_usdt_contract = IERC20(0x7d682e65EFC5C13Bf4E394B8f376C48e6baE0355);
        myPoolManager = new PoolManager();
        console.log("myPoolManager created at: %s", address(myPoolManager));
        // MyPool myPool = new MyPool(0x0bBF172103A6C9eA699c391FF63ffDE41C2c28C3, conflux_testnet_usdt_contract);
        // console.log("myPool created at: %s", address(myPool));
        // myPoolManager.addNewPool(address(myPool), 300);
        // MyPool myPool2 = new MyPool(address(myPoolManager), conflux_testnet_usdt_contract);
        // myPoolManager.addNewPool(address(myPool2), 60);
        vm.stopBroadcast();
    }

function run() public {
}

}
