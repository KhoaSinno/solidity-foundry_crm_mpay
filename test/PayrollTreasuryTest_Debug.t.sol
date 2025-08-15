// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PayrollTreasury} from "../src/PayrollTreasury.sol";
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

contract PayrollTreasuryTestDebug is Test {
    PayrollTreasury public treasury;

    address public constant manager = address(0x123);
    address public constant owner = address(0x456);
    address public constant employee = address(0x789);

    function setUp() public {
        vm.startPrank(owner);
        treasury = new PayrollTreasury(manager, 5 ether);
        vm.stopPrank();

        vm.deal(owner, 100 ether);
        vm.deal(manager, 100 ether);
        vm.deal(employee, 1 ether);
    }

    function testPayEmployeeDetailed() public {
        console.log("=== STARTING DETAILED PAY EMPLOYEE TEST ===");

        // Register employee with 1 ETH per month salary
        vm.prank(owner);
        treasury.registerEmployee(employee, 1 ether);

        PayrollTreasury.Employee memory emp = treasury.getEmployeeInfo(
            employee
        );
        console.log("Initial employee info:");
        console.log("  exists:", emp.exists);
        console.log("  rate:", emp.rate);
        console.log("  lastPaid:", emp.lastPaid);
        console.log("  totalPaid:", emp.totalPaid);

        // Fund treasury
        vm.prank(owner);
        treasury.deposit{value: 10 ether}();

        uint256 balanceBefore = treasury.getBalance();
        uint256 employeeBalanceBefore = employee.balance;
        console.log("");
        console.log("=== BEFORE PAYMENT ===");
        console.log("Treasury balance:", balanceBefore);
        console.log("Employee balance:", employeeBalanceBefore);

        // Fast-forward 15 days (half month)
        vm.warp(block.timestamp + 15 days);

        uint256 dueAmount = treasury.computeDue(emp.rate, emp.lastPaid);
        console.log("Due amount for 15 days:", dueAmount);
        uint256 halfEther = 500000000000000000;
        console.log("Expected (0.5 ETH):", halfEther);

        // Pay employee
        console.log("");
        console.log("=== EXECUTING PAYMENT ===");
        vm.prank(manager);
        treasury.payEmployee(payable(employee));

        // Check balances after payment
        uint256 balanceAfter = treasury.getBalance();
        uint256 employeeBalanceAfter = employee.balance;
        emp = treasury.getEmployeeInfo(employee);

        console.log("");
        console.log("=== AFTER PAYMENT ===");
        console.log("Treasury balance:", balanceAfter);
        console.log("Employee balance:", employeeBalanceAfter);
        console.log("Employee totalPaid:", emp.totalPaid);
        console.log("Employee lastPaid:", emp.lastPaid);
        console.log("Current timestamp:", block.timestamp);

        console.log("");
        console.log("=== BALANCE CHANGES ===");
        console.log("Treasury decrease:", balanceBefore - balanceAfter);
        console.log(
            "Employee increase:",
            employeeBalanceAfter - employeeBalanceBefore
        );

        // Assertions
        assertTrue(
            emp.lastPaid == block.timestamp,
            "Employee lastPaid should be current timestamp"
        );
        assertTrue(
            emp.totalPaid == dueAmount,
            "Employee totalPaid should match due amount"
        );
        assertTrue(
            balanceBefore - balanceAfter == dueAmount,
            "Treasury balance should decrease by due amount"
        );
        assertTrue(
            employeeBalanceAfter - employeeBalanceBefore == dueAmount,
            "Employee balance should increase by due amount"
        );

        console.log("");
        console.log("=== ALL TESTS PASSED ===");
    }

    function testPayEmployeeFullMonth() public {
        console.log("=== TESTING FULL MONTH PAYMENT ===");

        vm.prank(owner);
        treasury.registerEmployee(employee, 2 ether);

        vm.prank(owner);
        treasury.deposit{value: 10 ether}();

        // Fast-forward exactly 30 days
        vm.warp(block.timestamp + 30 days);

        PayrollTreasury.Employee memory emp = treasury.getEmployeeInfo(
            employee
        );
        uint256 dueAmount = treasury.computeDue(emp.rate, emp.lastPaid);

        console.log("Salary rate:", emp.rate);
        console.log("Due for 30 days:", dueAmount);
        console.log("Should be exactly:", emp.rate);

        assertTrue(dueAmount == emp.rate, "30 days should equal full salary");

        uint256 balanceBefore = treasury.getBalance();
        uint256 employeeBalanceBefore = employee.balance;

        vm.prank(manager);
        treasury.payEmployee(payable(employee));

        uint256 balanceAfter = treasury.getBalance();
        uint256 employeeBalanceAfter = employee.balance;

        console.log("Treasury change:", balanceBefore - balanceAfter);
        console.log(
            "Employee change:",
            employeeBalanceAfter - employeeBalanceBefore
        );

        assertTrue(
            balanceBefore - balanceAfter == 2 ether,
            "Treasury should decrease by 2 ETH"
        );
        assertTrue(
            employeeBalanceAfter - employeeBalanceBefore == 2 ether,
            "Employee should receive 2 ETH"
        );
    }

    function testPayEmployeeTwice() public {
        console.log("=== TESTING DOUBLE PAYMENT ===");

        vm.prank(owner);
        treasury.registerEmployee(employee, 1 ether);

        vm.prank(owner);
        treasury.deposit{value: 10 ether}();

        // First payment after 15 days
        vm.warp(block.timestamp + 15 days);

        uint256 balanceBefore1 = treasury.getBalance();
        vm.prank(manager);
        treasury.payEmployee(payable(employee));
        uint256 balanceAfter1 = treasury.getBalance();

        console.log("First payment amount:", balanceBefore1 - balanceAfter1);

        // Second payment after another 15 days
        vm.warp(block.timestamp + 15 days);

        uint256 balanceBefore2 = treasury.getBalance();
        vm.prank(manager);
        treasury.payEmployee(payable(employee));
        uint256 balanceAfter2 = treasury.getBalance();

        console.log("Second payment amount:", balanceBefore2 - balanceAfter2);

        PayrollTreasury.Employee memory emp = treasury.getEmployeeInfo(
            employee
        );
        console.log("Total paid after 2 payments:", emp.totalPaid);

        assertTrue(
            emp.totalPaid >= 0.9 ether && emp.totalPaid <= 1.1 ether,
            "Total should be around 1 ETH for full month"
        );
    }
}
