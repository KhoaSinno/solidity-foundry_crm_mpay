// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PayrollTreasury} from "../src/PayrollTreasury.sol";
import {Test} from "forge-std/Test.sol";
contract PayrollTreasuryTest is Test {
    PayrollTreasury public treasury;

    address public constant manager = address(0);
    address public constant owner = address(1);
    address public constant employee1 = address(2);

    // Mock ETH
    uint256 public constant AMOUNT_OF_USER = 100 ether;
    uint256 public constant AMOUNT_OF_EMPLOYEE = 50 ether;

    function setUp() public {
        treasury = new PayrollTreasury(manager, 3 ether);

        vm.deal(owner, AMOUNT_OF_USER);
        vm.deal(employee1, AMOUNT_OF_EMPLOYEE);
    }

    function testRegisterEmployee() public {
        
    }
}
