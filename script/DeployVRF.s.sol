// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {Script, console} from "forge-std/Script.sol";
import {VRFDeterministicCoordinatorV2_5Mock} from "../test/mocks/VRFDeterministicMock.sol";
import {LinkToken} from "../test/mocks/LinkTokenMock.sol";

contract DeployVRF is Script {
    function run() external returns (address, address) {
        uint96 baseFee = 0.25 ether; // 0.25 LINK
        uint96 gasPriceLink = 1e9; // 1 gwei LINK
        int256 weiPerUnitLink = 2e18;

        vm.startBroadcast();
        address vrfCoordinator = address(
            new VRFDeterministicCoordinatorV2_5Mock(
                baseFee,
                gasPriceLink,
                weiPerUnitLink
            )
        );
        address link = address(new LinkToken());
        vm.stopBroadcast();

        console.log("VRF Coordinator:", vrfCoordinator);
        console.log("Link Contract:", link);

        return (vrfCoordinator, link);
    }
}
