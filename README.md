# Raffle Smart Contract

A provably fair, verifiably random lottery smart contract written in Solidity.

# Getting Started

To set up the project, create a `.env` file in the root directory and add the following environment variables:

```
SEPOLIA_RPC_URL=<sepolia_rpc_url>
SEPOLIA_PRIVATE_KEY=<sepolia_private_key>
SUBSCRIPTION_ID=<subscription_id>
ANVIL_PRIVATE_KEY=<anvil_private_key>
ETHERSCAN_API_KEY=<etherscan_api_key>
```

Then, install the required dependencies using npm:

```bash
make install
```

Deploy the smart contract on Anvil with:

```bash
make deploy
```

To deploy the smart contract on Sepolia, use:

```bash
make deploy ARGS="--network sepolia"
```

# Testing

To run the tests against a local Anvil instance, use:

```bash
make test
```

To run the tests on Sepolia, use:

```bash
make test ARGS="--network sepolia"
```

## Tech Stack

- **[Solidity](https://docs.soliditylang.org/)**: Smart contract programming language
- **[Foundry](https://book.getfoundry.sh/)**: Development framework for building, testing, and deploying smart contracts
