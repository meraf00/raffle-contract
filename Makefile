-include .env

.PHONY: all test deploy

help:
	@echo "Available commands:"
	@echo "  make help     - Show this help message"
	@echo "  make install  - Install dependencies"
	@echo "  make build    - Build the project"
	@echo "  make test     - Run tests"
	@echo "  make deploy [ARGS="--network sepolia"]   - Deploy the project"

install:
	forge install

build:
	forge build	

test:		
	forge test	

anvil:
	anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1


NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(ANVIL_PRIVATE_KEY) --broadcast -vvvv --disable-block-gas-limit 
ifeq ($(findstring --network sepolia, $(ARGS)), --network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(SEPOLIA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy-vrf:
	@forge script script/DeployVRF.s.sol:DeployVRF $(NETWORK_ARGS) --optimizer-runs 5

deploy:
	@forge script script/DeployRaffle.s.sol:DeployRaffle $(NETWORK_ARGS) --optimizer-runs 5

