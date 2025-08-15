-include .env

deploy-sepolia-testnet:
	@forge script script/PayrollTreasuryScript.s.sol:PayrollTreasuryScript --rpc-url ${SEPOLIA_RPC_URL} --broadcast --account foundry-alchemy-learn --verify --etherscan-api-key ${ETHERSCAN_API_KEY} 

verify-sepolia-testnet:
	@forge verify-contract 0x14E257cbD2D08f289faA253283317646f0f819eE script/PayrollTreasuryScript.s.sol:PayrollTreasuryScript --rpc-url ${SEPOLIA_RPC_URL} --etherscan-api-key ${ETHERSCAN_API_KEY}

deploy-sepolia-anvil:
	@forge script script/PayrollTreasuryScript.s.sol:PayrollTreasuryScript --rpc-url http://127.0.0.1:8545 --broadcast --account sinoo-anvil --sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
