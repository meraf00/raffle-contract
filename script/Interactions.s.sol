// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {VRFDeterministicCoordinatorV2_5Mock} from "../test/mocks/VRFDeterministicMock.sol";
import {HelperConfig, SEPOLIA_CHAIN_ID} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/mocks/LinkTokenMock.sol";
import {DeployVRF} from "./DeployVRF.s.sol";

contract Subscription is Script {
    uint96 public constant FUND_AMOUNT = 20 ether;

    function createSubscription(
        address vrfCoordinator,
        uint256 deployerKey
    ) public returns (uint256) {
        uint256 subId = 0;
        vm.startBroadcast(deployerKey);
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            subId = VRFDeterministicCoordinatorV2_5Mock(vrfCoordinator)
                .createSubscription();
        } else {
            subId = VRFDeterministicCoordinatorV2_5Mock(vrfCoordinator)
                .deterministicCreateSubscription();
        }
        vm.stopBroadcast();
        return subId;
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subId,
        address link,
        uint256 deployerKey
    ) public {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            vm.startBroadcast(deployerKey);
            LinkToken(link).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerKey);
            VRFDeterministicCoordinatorV2_5Mock(vrfCoordinator)
                .fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        }
    }

    function addConsumer(
        address vrfCoordinator,
        uint256 subId,
        address consumer,
        uint256 deployerKey
    ) public {
        vm.startBroadcast(deployerKey);
        VRFDeterministicCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subId,
            consumer
        );
        vm.stopBroadcast();
    }

    function run() external returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();
        (, , , , , , , uint256 deployerKey) = helperConfig
            .activeNetworkConfig();

        DeployVRF deployVRF = new DeployVRF();
        (address vrfCoordinator, address link) = deployVRF.run();

        uint256 subId = createSubscription(vrfCoordinator, deployerKey);
        fundSubscription(vrfCoordinator, subId, link, deployerKey);

        return subId;
    }
}
