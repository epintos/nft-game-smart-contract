-include .env

.PHONY: all test deploy

build :; forge build

test :; forge test

install :; forge install foundry-rs/forge-std --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit

deploy-sepolia :
	@forge script script/DeployNftGame.s.sol:DeployNftGame --rpc-url $(SEPOLIA_RPC_URL) --account $(SEPOLIA_ACCOUNT) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-anvil :
	@forge script script/DeployNftGame.s.sol:DeployNftGame --rpc-url $(RPC_URL) --account $(ANVIL_ACCOUNT) --broadcast -vvvv
