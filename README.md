# PayrollTreasury Smart Contract - CRM M-Pay

``` bash
https://sepolia.etherscan.io/address/0xde46e252426ac4b1a57f6e8e09f3a8639e9ec1b2#code
```

## 📋 Tổng Quan

**PayrollTreasury** là một smart contract được xây dựng để quản lý ngân quỹ và hệ thống trả lương tự động cho doanh nghiệp. Contract này cung cấp:

- ✅ **Quản lý ngân quỹ công ty** (nạp/rút tiền với giới hạn hàng ngày)
- ✅ **Quản lý nhân viên** (thêm/xóa/cập nhật thông tin)
- ✅ **Hệ thống trả lương tự động** (tính toán và chi trả theo chu kỳ 30 ngày)
- ✅ **Kiểm soát quyền hạn** (chỉ manager mới có quyền quản lý)
- ✅ **Theo dõi lịch sử** (events tracking mọi giao dịch)

## 🛠️ Công Nghệ Sử Dụng

- **Solidity ^0.8.13** - Ngôn ngữ smart contract
- **Foundry** - Framework phát triển và testing
- **OpenZeppelin** - Security standards
- **Next.js** - Frontend (tích hợp sau)

## 🏗️ Cấu Trúc Dự Án

```
solidity-foundry_crm_mpay/
├── src/
│   └── PayrollTreasury.sol           # Main contract
├── test/
│   └── PayrollTreasuryTest.t.sol     # Test cases
├── script/
│   ├── Counter.s.sol                 # Deploy script (template)
│   └── PayrollTreasuryDeploy.s.sol   # Deploy script (sẽ tạo)
├── lib/
│   └── forge-std/                    # Foundry standard library
├── foundry.toml                      # Foundry config
└── README.md                         # Hướng dẫn này
```

## 🚀 Bắt Đầu Nhanh

### 1. Cài Đặt Prerequisites

```bash
# Cài đặt Foundry (nếu chưa có)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Kiểm tra version
forge --version
cast --version
anvil --version
```

### 2. Clone và Setup Project

```bash
# Clone project (hoặc đã có)
cd w:\WorkSpace_IT\nextjs\mpay_project\solidity-foundry_crm_mpay

# Install dependencies
forge install

# Build contract
forge build
```

### 3. Chạy Tests

```bash
# Chạy tất cả tests
forge test

# Chạy tests với details
forge test -vvv

# Chạy gas report
forge test --gas-report
```

## 📚 Hướng Dẫn Step-by-Step

### STEP 1: Hiểu Contract PayrollTreasury

#### 🔧 State Variables (Biến Trạng Thái)

```solidity
address public treasuryManager;        // Người quản lý duy nhất
uint256 public dailyLimit;            // Giới hạn rút tiền/ngày (wei)
uint256 public lastWithdrawalDay;     // Ngày rút tiền cuối cùng
uint256 public dailyWithdrawn;        // Số tiền đã rút trong ngày

mapping(address => Employee) private employees;  // Mapping nhân viên
address[] private employeeList;                  // Danh sách địa chỉ nhân viên
```

#### 👤 Employee Struct

```solidity
struct Employee {
    bool exists;        // Nhân viên có tồn tại không
    uint256 rate;       // Lương mỗi 30 ngày (tính bằng wei)
    uint256 lastPaid;   // Thời điểm trả lương cuối (timestamp)
    uint256 totalPaid;  // Tổng số tiền đã trả
}
```

#### 📡 Events (Sự Kiện)

```solidity
event Deposit(address indexed from, uint256 amount);
event Withdraw(address indexed to, uint256 amount, uint256 timestamp);
event EmployeeRegistered(address indexed emp, uint256 rate, uint256 timestamp);
event PayrollRun(address indexed admin, uint256 timestamp);
event Payment(address indexed to, uint256 amount, uint256 timestamp);
```

### STEP 2: Các Chức Năng Chính

#### 🏦 Treasury Functions

**1. Deposit (Nạp tiền)**

```solidity
function deposit() external payable
```

- Bất kỳ ai cũng có thể nạp ETH vào contract
- Emit event `Deposit`

**2. Withdraw (Rút tiền)**

```solidity
function withdraw(address payable to, uint256 amount) public
```

- Kiểm tra giới hạn daily limit
- Reset counter nếu sang ngày mới
- Chuyển ETH và emit event `Withdraw`

#### 👥 Employee Management

**3. Register Employee (Đăng ký nhân viên)**

```solidity
function registerEmployee(address emp, uint256 rate) public
```

- Thêm nhân viên mới với mức lương rate (wei/30 ngày)
- Kiểm tra không trùng lặp
- Emit event `EmployeeRegistered`

**4. Get Employee Info (Xem thông tin nhân viên)**

```solidity
function getEmployeeInfo(address emp) public view returns (...)
```

- Trả về: exists, rate, lastPaid, totalPaid

#### 💰 Payroll Functions

**5. Compute Due (Tính lương còn thiếu)**

```solidity
function computeDue(uint256 rate, uint256 lastPaid) public view returns (uint256)
```

- Tính số tiền lương dựa trên thời gian đã làm
- Formula: `rate * ((now - lastPaid) / 30 days)`

**6. Run Payroll (Chạy bảng lương)**

```solidity
function runPayroll() public onlyManager
```

- Loop qua tất cả nhân viên
- Tính và trả lương cho từng người
- Cập nhật lastPaid và totalPaid
- Chỉ manager mới được gọi

### STEP 3: Testing Contract

Tạo test cases để đảm bảo contract hoạt động đúng:

```solidity
// Ví dụ test case
function test_DepositAndWithdraw() public {
    // Setup
    uint256 depositAmount = 5 ether;
    vm.deal(address(this), depositAmount);
    
    // Deposit
    treasury.deposit{value: depositAmount}();
    assertEq(treasury.getBalance(), depositAmount);
    
    // Withdraw (as manager)
    vm.prank(manager);
    treasury.withdraw(payable(address(this)), 1 ether);
    assertEq(treasury.getBalance(), 4 ether);
}
```

### STEP 4: Deploy Contract

#### 🌐 Deploy Local (Anvil)

```bash
# Terminal 1: Start local blockchain
anvil

# Terminal 2: Deploy
forge script script/PayrollTreasuryDeploy.s.sol:PayrollTreasuryScript \
    --fork-url http://localhost:8545 \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --broadcast
```

#### 🔗 Deploy Testnet

```bash
# Deploy to Sepolia testnet
forge script script/PayrollTreasuryDeploy.s.sol:PayrollTreasuryScript \
    --rpc-url https://rpc.sepolia.org \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY
```

### STEP 5: Tương Tác với Contract

#### 📞 Sử dụng Cast Commands

```bash
# 1. Deposit ETH
cast send <CONTRACT_ADDRESS> "deposit()" \
    --value 5ether \
    --private-key <PRIVATE_KEY> \
    --rpc-url <RPC_URL>

# 2. Register employee (1 ETH per 30 days)
cast send <CONTRACT_ADDRESS> "registerEmployee(address,uint256)" \
    <EMPLOYEE_ADDRESS> 1000000000000000000 \
    --private-key <PRIVATE_KEY> \
    --rpc-url <RPC_URL>

# 3. Check contract balance
cast call <CONTRACT_ADDRESS> "getBalance()" --rpc-url <RPC_URL>

# 4. Get employee info
cast call <CONTRACT_ADDRESS> "getEmployeeInfo(address)" \
    <EMPLOYEE_ADDRESS> --rpc-url <RPC_URL>

# 5. Run payroll (only manager)
cast send <CONTRACT_ADDRESS> "runPayroll()" \
    --private-key <MANAGER_PRIVATE_KEY> \
    --rpc-url <RPC_URL>
```

## 🔐 Security Features

### Access Control

- **onlyManager modifier**: Chỉ manager mới có quyền rút tiền và chạy payroll
- **Daily withdrawal limit**: Giới hạn số tiền rút mỗi ngày
- **Employee validation**: Kiểm tra địa chỉ hợp lệ khi đăng ký

### Best Practices Applied

- ✅ **Reentrancy protection**: Sử dụng Checks-Effects-Interactions pattern
- ✅ **Input validation**: Kiểm tra tất cả inputs
- ✅ **Event emission**: Tracking mọi thay đổi quan trọng
- ✅ **Gas optimization**: Efficient loops và storage usage

## 📊 Gas Estimates

| Function | Gas Cost (approx) |
|----------|-------------------|
| deposit() | ~21,000 |
| registerEmployee() | ~50,000 |
| withdraw() | ~35,000 |
| runPayroll() | ~100,000+ (depends on employee count) |
| getEmployeeInfo() | ~view (free) |

## 🧪 Command Reference

### Build & Test Commands

```bash
forge build                    # Compile contracts
forge test                     # Run tests
forge test -vvv               # Verbose test output
forge test --gas-report       # Show gas usage
forge fmt                     # Format code
forge clean                   # Clean cache
```

### Deploy Commands

```bash
forge script <script> --rpc-url <url> --private-key <key> --broadcast
forge verify-contract <address> <contract> --etherscan-api-key <key>
```

### Cast Commands

```bash
cast send <to> <sig> [args] --private-key <key>    # Send transaction
cast call <to> <sig> [args]                        # Call view function
cast balance <address>                              # Check balance
cast block-number                                   # Current block
```

## 🗺️ Roadmap

### Phase 1: MVP (Current) ✅

- [x] Basic treasury management
- [x] Employee registration
- [x] Automatic payroll
- [x] Access control

### Phase 2: Enhanced Features 🔄

- [ ] Multiple token support (ERC20)
- [ ] Role-based permissions
- [ ] Employee categories
- [ ] Bonus system

### Phase 3: Integration 🔮

- [ ] Next.js frontend
- [ ] MetaMask integration
- [ ] Real-time dashboard
- [ ] Mobile app

## 🆘 Troubleshooting

### Common Issues

**1. "Not authorized" error**

- Đảm bảo đang gọi từ manager address
- Kiểm tra private key đúng

**2. "Insufficient balance" error**

- Contract cần có đủ ETH để trả lương
- Gọi `deposit()` để nạp thêm tiền

**3. "Daily withdrawal limit exceeded"**

- Chờ sang ngày mới hoặc tăng dailyLimit
- Kiểm tra `dailyWithdrawn` và `dailyLimit`

**4. Test failures**

- Chạy `forge clean` và `forge build`
- Kiểm tra version Solidity

## 🤝 Contributing

1. Fork project
2. Create feature branch: `git checkout -b feature/AmazingFeature`
3. Commit changes: `git commit -m 'Add AmazingFeature'`
4. Push branch: `git push origin feature/AmazingFeature`
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Contact

- **Developer**: KhoaSinno
- **Repository**: [solidity-foundry_crm_mpay](https://github.com/KhoaSinno/solidity-foundry_crm_mpay)
- **Issues**: [GitHub Issues](https://github.com/KhoaSinno/solidity-foundry_crm_mpay/issues)

---

## 🎯 Quick Start Commands

```bash
# 1. Build
forge build

# 2. Test
forge test -vvv

# 3. Start local blockchain
anvil

# 4. Deploy locally
forge script script/PayrollTreasuryDeploy.s.sol:PayrollTreasuryScript --fork-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

# 5. Interact
cast send <CONTRACT_ADDRESS> "deposit()" --value 1ether --private-key <KEY> --rpc-url http://localhost:8545
```

**Happy Coding! 🚀**
