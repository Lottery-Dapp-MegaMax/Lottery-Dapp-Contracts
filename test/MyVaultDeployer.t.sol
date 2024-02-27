// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "../src/MyVaultDeployer.sol";
import "../src/MyToken.sol";


contract MyVaultDeployerTest is Test {

    address public base_address = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

    function testDeploy() public {
        console.log(address(this));
        MyToken token = new MyToken();
        console.log("Token address: %s", address(token));
        MyVaultDeployer deployer = new MyVaultDeployer();
        console.log("Deployer address: %s", address(deployer));
        console.log("Owner of deployer: %s", address(deployer.owner()));
        deployer.deployNewVault(token);
        console.log("Deployed vault 0: %s", address(deployer.activeVaults(0)));
        // console.log("Deployed vault 1: %s", address(deployer.activeVaults(1)));
        console.log("Token address of vault 0: %s", address(MyVault(deployer.activeVaults(0)).asset()));
    }
}