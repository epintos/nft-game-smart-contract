-include .env

.PHONY: all test deploy

build :; forge build

test :; forge test

install :
	forge install cyfrin/foundry-devops@0.2.2 --no-commit && \
	forge install foundry-rs/forge-std@v1.9.5 --no-commit && \
	forge install openzeppelin/openzeppelin-contracts@v5.2.0 --no-commit && \
	forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 --no-commit

deploy-sepolia :
	@forge script script/DeployNFTGame.s.sol:DeployNFTGame --rpc-url $(SEPOLIA_RPC_URL) --account $(SEPOLIA_ACCOUNT) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-anvil :
	@forge script script/DeployNFTGame.s.sol:DeployNFTGame --rpc-url $(RPC_URL) --account $(ANVIL_ACCOUNT) --broadcast -vvvv

fund-account :
	cast send $(SEPOLIA_ACCOUNT_ADDRESS) --value 0.01ether --rpc-url $(RPC_URL) --account $(ANVIL_ACCOUNT)

# Example: make mint-nft CHARACTER_INDEX=0
mint-nft :
	@CHARACTER_INDEX=$(CHARACTER_INDEX) \
	forge script script/Interactions.s.sol:MintNFT --rpc-url $(RPC_URL) --account $(SEPOLIA_ACCOUNT) --broadcast -vvvv

attack:
	@TOKEN_ID=$(TOKEN_ID) \
	forge script script/Interactions.s.sol:AttackNFT --rpc-url $(RPC_URL) --account $(SEPOLIA_ACCOUNT) --broadcast -vvvv
