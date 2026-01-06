// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {DeployVRF} from "../../script/DeployVRF.s.sol";
import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Subscription} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig, address, address) {
        HelperConfig helperConfig = new HelperConfig();

        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint256 subscriptionId,
            uint32 callbackGasLimit,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        DeployVRF deployVRF = new DeployVRF();
        (vrfCoordinator, link) = deployVRF.run();

        Subscription subscription = new Subscription();

        if (subscriptionId == 0) {
            subscriptionId = subscription.createSubscription(
                vrfCoordinator,
                deployerKey
            );
            subscription.fundSubscription(
                vrfCoordinator,
                subscriptionId,
                link,
                deployerKey
            );
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        subscription.addConsumer(
            vrfCoordinator,
            subscriptionId,
            address(raffle),
            deployerKey
        );

        return (raffle, helperConfig, vrfCoordinator, link);
    }
}
