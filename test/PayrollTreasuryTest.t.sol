// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PayrollTreasury} from "../src/PayrollTreasury.sol";

contract PayrollTreasuryTest {
    PayrollTreasury public payrollTreasury;

    function setUp() public {
        payrollTreasury = new PayrollTreasury();
    }
}
