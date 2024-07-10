//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {OurToken} from "../src/OurToken.sol";

Contract DeployOurToken is Script {
   uint256 pulic constant INITIAL_SUPPLY = 1000 ether;


    function run() {
        vm.startBroadcast();
        new OurToken(INITIAL_SUPPLY); 
        vm.stopBroadcast();
    }
}