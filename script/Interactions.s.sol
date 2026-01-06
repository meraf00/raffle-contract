// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig, SEPOLIA_CHAIN_ID} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/mocks/LinkTokenMock.sol";

contract Subscription is Script {
    uint96 public constant FUND_AMOUNT = 20 ether;

    function createSubscription(
        address vrfCoordinator,
        uint256 deployerKey
    ) public returns (uint256) {
        vm.startBroadcast(deployerKey);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
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
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT
            );
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
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, consumer);
        vm.stopBroadcast();
    }

    function run() external returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            ,
            ,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        uint256 subId = createSubscription(vrfCoordinator, deployerKey);
        fundSubscription(vrfCoordinator, subId, link, deployerKey);

        return subId;
    }
}
