// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {Script} from "forge-std/Script.sol";

uint256 constant SEPOLIA_CHAIN_ID = 11155111;
address constant SEPOLIA_CHAIN_VRF_COORDINATOR = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
bytes32 constant SEPOLIA_CHAIN_GAS_LANE_KEY_HASH = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
address constant SEPOLIA_CHAIN_LINK_TOKEN_CONTRACT = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: SEPOLIA_CHAIN_VRF_COORDINATOR,
                gasLane: SEPOLIA_CHAIN_GAS_LANE_KEY_HASH,
                subscriptionId: vm.envUint("SUBSCRIPTION_ID"),
                callbackGasLimit: 150_000,
                link: SEPOLIA_CHAIN_LINK_TOKEN_CONTRACT,
                deployerKey: vm.envUint("SEPOLIA_PRIVATE_KEY")
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }

        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: vm.envAddress("VRF_COORDINATOR_ADDRESS"),
                gasLane: 0x0,
                subscriptionId: 0,
                callbackGasLimit: 150_000,
                link: vm.envAddress("LINK_CONTRACT_ADDRESS"),
                deployerKey: vm.envUint("ANVIL_PRIVATE_KEY")
            });
    }
}
