// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PayrollTreasury} from "../src/PayrollTreasury.sol";

contract PayrollTreasuryScript is Script {
    PayrollTreasury public payrollTreasury;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        payrollTreasury = new PayrollTreasury(
            vm.envAddress("MANAGER_ADDRESS"),
            vm.envUint("DAILY_LIMIT")
        );

        vm.stopBroadcast();
    }
}
