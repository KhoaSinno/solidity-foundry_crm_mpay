// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract PayrollTreasury {
    // ==== Logic CRM onchain MPAY ====

    // State
    address immutable i_owner;
    address[] public empListAddress;

    struct Employee {
        address empAddress;
        uint256 salary;
        uint256 lastPaid;
    }

    mapping(address => Employee) public employees;

    // Events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    // Errors
    error NotOwner();

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // Constructor
    constructor() {
        i_owner = msg.sender;
    }

    // ==== Functions ====

    // == Reader ==
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getEmpListAddress() public view returns (address[] memory) {
        return empListAddress;
    }

    // == Writer ==
    function deposit() external payable {
        // Logic for deposit
    }

    function withdraw(uint256 amount) external onlyOwner {
        // Logic for withdraw
    }

    function setNewEmpAddress(address empAddress) public {
        empListAddress.push(empAddress);
    }

    function runPayroll() public {
        // 1. Loop all employees in empListAddress
        // 2. Check condition
        // 3. Pay employee (True)
        // 4. Update lastPaid
        // 5. Emit event
    }

    function payEmployee(address empAddress) public view {
        Employee storage employee = employees[empAddress];
        // Logic to pay employee
    }
}
