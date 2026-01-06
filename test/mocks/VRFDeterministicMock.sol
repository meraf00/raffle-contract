// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {EnumerableSet} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";

contract VRFDeterministicCoordinatorV2_5Mock is VRFCoordinatorV2_5Mock {
    using EnumerableSet for EnumerableSet.UintSet;

    constructor(
        uint96 _baseFee,
        uint96 _gasPrice,
        int256 _weiPerUnitLink
    ) VRFCoordinatorV2_5Mock(_baseFee, _gasPrice, _weiPerUnitLink) {}

    /**
     * @notice Create a deterministic subscription id on forge EVM and Anvil during broadcast.
     * @dev Uses keccak(msg.sender, s_currentSubNonce) instead of block data to make
     *      ids stable across runs, enabling reproducible tests and simpler assertions.
     *      Mirrors the state updates and event of createSubscription, while preserving
     *      the original msg.sender (unlike calling this.createSubscription()).
     *      Predictable ids are acceptable here because this contract is a mock.
     *
     *      Forge runs scripts in two phases: simulate (dry-run) then broadcast. If a
     *      subId is derived from blockhash/contract address, the simulated subId will
     *      differ from the broadcasted subId on Anvil (different block/address),
     *      causing subsequent steps (funding/adding consumers) to reference a wrong id
     *      and fail. Removing block/address from the id makes simulate == broadcast.
     */
    function deterministicCreateSubscription()
        external
        nonReentrant
        returns (uint256 subId)
    {
        // Generate a subscription id that is deterministic.
        uint64 currentSubNonce = s_currentSubNonce;
        subId = uint256(
            keccak256(abi.encodePacked(msg.sender, currentSubNonce))
        );
        // Increment the subscription nonce counter.
        s_currentSubNonce = currentSubNonce + 1;
        // Initialize storage variables.
        address[] memory consumers = new address[](0);
        s_subscriptions[subId] = Subscription({
            balance: 0,
            nativeBalance: 0,
            reqCount: 0
        });
        s_subscriptionConfigs[subId] = SubscriptionConfig({
            owner: msg.sender,
            requestedOwner: address(0),
            consumers: consumers
        });
        // Update the s_subIds set, which tracks all subscription ids created in this contract.
        // This is a mock contract, so we don't need to worry about the security of the subscription ids.
        s_subIds.add(subId);

        emit SubscriptionCreated(subId, msg.sender);
        return subId;
    }
}
