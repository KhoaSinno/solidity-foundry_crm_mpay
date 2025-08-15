// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract PayrollTreasury {
    // ==== Logic CRM onchain MPAY ====
    /**

    1. Management employee: CRUD (address, salary, status)
    2. Deposit/Withdraw: Owner can deposit and withdraw funds
    3. Payroll: Owner can run payroll to pay employees based on their salary
    4. Tracking history: Owner can track the payment history of each employee

     */

    // --- State variables ---

    address public immutable i_manager;
    address public immutable i_owner;
    uint256 public dailyLimit; // Limit withdraw per day
    uint256 public lastDayWithdraw; // Last withdraw timestamp
    uint256 public totalWithdrawnToday; // Total withdrawn today

    struct Employee {
        bool exists; // Check if employee exists
        uint256 rate; // Salary per month (30 days)
        uint256 lastPaid; // Last paid timestamp
        uint256 totalPaid;
    }

    address[] private employeeListAddress;
    mapping(address => Employee) private employees;

    // --- Events ---
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 timestamp);
    event EmployeeAdded(
        address indexed employee,
        uint256 salary,
        uint256 timestamp
    );
    event Payment(address indexed to, uint256 amount, uint256 timestamp);
    event EmployeeSalaryUpdated(address indexed employee, uint256 newSalary);
    event PayrollRun(address indexed employee, uint256 timestamp);
    event EmployeeRemoved(address indexed employee, uint256 timestamp);

    // --- Errors ---
    error NotOwner();

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != i_manager && msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // --- Constructor ---
    constructor(address _manager, uint256 _dailyLimit) {
        i_manager = _manager;
        i_owner = msg.sender;
        dailyLimit = _dailyLimit;
        lastDayWithdraw = block.timestamp / 86400;
        totalWithdrawnToday = 0;
    }

    // --- Functions ---

    // == Writer ==
    /**
     * Everyone can deposit funds into the contract
     * Emits a Deposited event
     *
     */
    function deposit() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");

        lastDayWithdraw = block.timestamp / 86400;

        uint256 currentDay = block.timestamp / 86400;

        if (lastDayWithdraw - currentDay != 1) {
            totalWithdrawnToday = 0;
        }

        totalWithdrawnToday += amount;

        require(totalWithdrawnToday <= dailyLimit, "Exceeds daily limit");

        emit Withdrawn(i_manager, amount, block.timestamp);
    }

    function payEmployee(address payable empAddress) public onlyOwner {
        Employee storage employee = employees[empAddress];
        require(employee.exists, "Employee does not exist");

        uint256 due = computeDue(employee.rate, employee.lastPaid);

        require(address(this).balance >= due, "Insufficient balance");

        // send funds from vault of contract
        (bool sent, ) = empAddress.call{value: due}("");
        require(sent, "Failed to send Ether");

        employee.lastPaid = block.timestamp;
        employee.totalPaid += due;

        emit Payment(empAddress, due, block.timestamp);
    }

    function runPayroll() public onlyOwner {
        // 1. Loop all employees in employeeListAddress
        // 2. Check condition
        // 3. Pay employee (True)
        // 4. Update lastPaid
        // 5. Emit event

        for (uint256 i = 0; i < employeeListAddress.length; i++) {
            address empAddress = employeeListAddress[i];
            uint256 due = computeDue(
                employees[empAddress].rate,
                employees[empAddress].lastPaid
            );
            if (due > 0) {
                payEmployee(payable(empAddress));
            }
        }
    }

    function computeDue(
        uint256 rate,
        uint256 lastPaid
    ) public view returns (uint256) {
        uint256 due = 0;
        uint256 period = 30 days;
        require(rate > 0, "Invalid salary rate");
        require(lastPaid < block.timestamp, "Invalid last paid timestamp");

        due = (rate * (block.timestamp - lastPaid)) / period; // Calculate due amount based on rate and time since last paid
        return due;
    }

    function registerEmployee(
        address empAddress,
        uint256 rate
    ) public onlyOwner {
        require(rate > 0, "Invalid salary");
        Employee storage e = employees[empAddress];
        require(!e.exists, "Employee already exists");
        e.rate = rate;
        e.exists = true;
        e.lastPaid = block.timestamp;
        e.totalPaid = 0;

        employeeListAddress.push(empAddress);

        emit EmployeeAdded(empAddress, rate, block.timestamp);
    }

    function setNewEmployeeSalary(
        address empAddress,
        uint256 rate
    ) public onlyOwner {
        // require(msg.sender == i_manager, "Only manager can set employee salary");
        require(rate > 0, "Invalid salary");
        Employee storage e = employees[empAddress];
        require(e.exists, "Employee does not exist");
        e.rate = rate;

        emit EmployeeSalaryUpdated(empAddress, rate);
    }

    function removeEmployee(address empAddress) external onlyOwner {
        Employee storage e = employees[empAddress];
        require(e.exists, "Employee does not exist");
        e.exists = false;

        emit EmployeeRemoved(empAddress, block.timestamp);
    }

    // == Reader ==
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getEmployeeInfo(
        address empAddress
    ) public view returns (Employee memory) {
        return employees[empAddress];
    }

    function getEmployeeListAddress() public view returns (address[] memory) {
        return employeeListAddress;
    }
}
