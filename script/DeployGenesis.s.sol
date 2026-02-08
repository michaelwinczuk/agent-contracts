// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Genesis} from "../contracts/src/Genesis.sol";

contract DeployGenesis is Script {
    function run() external {
        vm.startBroadcast();

        Genesis genesis = new Genesis();

        console.log("Genesis deployed at:", address(genesis));
        console.log("Owner:", genesis.owner());
        console.log("isAlive:", genesis.isAlive());

        vm.stopBroadcast();
    }
}
