// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    address public player = makeAddr("player");
    uint public constant STARTING_USER_BALANCE = 10 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();

        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link
        ) = helperConfig.activeNetworkConfig();

        vm.deal(player, STARTING_USER_BALANCE);
    }

    function test_InitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    // Test Group
    // Enter Raffle
    function test_EnterRaffleRevertsWhenUserDoesNotPayEnough() public {
        vm.prank(player);

        bytes memory insufficientBalanceError = abi.encodeWithSelector(
            Raffle.Raffle__InsufficientBalance.selector,
            0,
            entranceFee
        );

        vm.expectRevert(insufficientBalanceError);
        raffle.enter();
    }

    function test_EnterRaffleRevertsWhenGameIsClosed() public {
        vm.prank(player);
        raffle.enter{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__GameNotOpen.selector);
        vm.prank(player);
        raffle.enter{value: entranceFee}();
    }

    function test_EnterRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(player);

        raffle.enter{value: entranceFee}();

        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == player);
    }

    function test_EnterRaffleEmitsPlayerEntered() public {
        vm.prank(player);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit Raffle.PlayerEntered(player);

        raffle.enter{value: entranceFee}();
    }
}
