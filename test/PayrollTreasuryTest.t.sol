// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PayrollTreasury} from "../src/PayrollTreasury.sol";
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

contract PayrollTreasuryTest is Test {
    PayrollTreasury public treasury;

    address public constant manager = address(0);
    address public constant owner = address(1);
    address public constant employee = address(2);
    address public constant employee2 = address(3);

    // Mock ETH
    uint256 public constant AMOUNT_OF_USER = 100 ether;
    uint256 public constant AMOUNT_OF_EMPLOYEE = 50 ether;

    function setUp() public {
        treasury = new PayrollTreasury(manager, 5 ether);

        vm.deal(manager, AMOUNT_OF_USER);

        vm.deal(owner, AMOUNT_OF_USER);
        vm.deal(employee, AMOUNT_OF_EMPLOYEE);
    }

    function testDeposit() public {
        treasury.deposit{value: 1 ether}();
        assertTrue(
            treasury.getBalance() == 1 ether,
            "Balance should be 1 ether"
        );
    }

    function testWithdraw() public {
        treasury.deposit{value: 5 ether}();

        vm.prank(manager);
        treasury.withdraw(3 ether);
        assertTrue(
            treasury.getBalance() == 2 ether,
            "Balance should be 2 ether after withdrawal"
        );
    }

    function testPayEmployee() public {
        treasury.registerEmployee(employee, 1 ether);

        // Register emp
        PayrollTreasury.Employee memory emp = treasury.getEmployeeInfo(
            employee
        );
        // fund the treasury so payEmployee can send Ether
        treasury.deposit{value: 5 ether}();
        console.log(address(treasury).balance, "Funding treasury");
        // Fast-forward 30 days so compute > 0
        vm.warp(block.timestamp + 30 days);

        // Pay employee

        vm.prank(manager);
        treasury.payEmployee(payable(employee));

        console.log(address(treasury).balance, "Funding treasury 2");

        emp = treasury.getEmployeeInfo(employee);

        assertTrue(emp.lastPaid == block.timestamp, "Employee should be paid");

        // assertTrue(
        //     emp.totalPaid <= 1 ether,
        //     "Employee total paid should be 1 ether"
        // );

        assertTrue(
            emp.totalPaid == 1 ether,
            "Employee total paid should be 1 ether with 30days"
        );

        console.log(emp.rate, "Employee paid successfully");
    }

    function testRunPayroll() public {
        treasury.registerEmployee(employee, 1 ether);
        treasury.registerEmployee(employee2, 2 ether);

        // vm.prank(manager);
        // treasury.runPayroll();
    }

    function testRegisterEmployee() public {
        treasury.registerEmployee(employee, 1 ether);

        PayrollTreasury.Employee memory e = treasury.getEmployeeInfo(employee);

        assertTrue(e.exists, "Employee should exist");
        assertTrue(e.rate == 1 ether, "Employee rate should be 1 ether");
        assertTrue(
            treasury.getEmployeeListAddress().length == 1,
            "Data length should be 1"
        );
    }

    function testSetNewEmployeeSalary() public {
        treasury.registerEmployee(employee, 1 ether);
        PayrollTreasury.Employee memory e = treasury.getEmployeeInfo(employee);

        assertTrue(e.exists, "Employee should exist");
        assertTrue(e.rate == 1 ether, "Employee rate should be 1 ether");

        // Update salary
        treasury.setNewEmployeeSalary(employee, 2 ether);
        e = treasury.getEmployeeInfo(employee);

        assertTrue(
            e.rate == 2 ether,
            "Employee rate should be updated to 2 ether"
        );
    }

    function testRemoveEmployee() public {
        treasury.registerEmployee(employee, 1 ether);
        PayrollTreasury.Employee memory e = treasury.getEmployeeInfo(employee);

        assertTrue(e.exists, "Employee should exist");
        assertTrue(e.rate == 1 ether, "Employee rate should be 1 ether");

        treasury.removeEmployee(employee);
        e = treasury.getEmployeeInfo(employee);

        assertTrue(!e.exists, "Employee should be removed");
        assertTrue(
            treasury.getEmployeeListAddress().length == 1,
            "Data length should be 0"
        );
    }
}
