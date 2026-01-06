// SPDX-License-Identifier: MIT

pragma solidity ^0.8.33;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig, SEPOLIA_CHAIN_ID} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

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
        (raffle, helperConfig, vrfCoordinator, link) = deployRaffle.run();

        (
            entranceFee,
            interval,
            ,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            ,

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

    function test_EnterRaffleRevertsWhenGameIsClosed() public runSingleRound {
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

    // Test Group
    // Check upkeep
    function test_CheckUpkeepReturnsFalseIfItHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function test_CheckUpkeepReturnsFalseIfRaffleNotOpen()
        public
        runSingleRound
    {
        vm.prank(player);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function test_CheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        vm.prank(player);
        raffle.enter{value: entranceFee}();

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function test_CheckUpkeepReturnsTrueWhenParamsAreGood() public {
        vm.prank(player);
        raffle.enter{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(upkeepNeeded);
    }

    // Test Group
    // Perform Upkeep
    function test_PerformUpkeepRunsOnlyWhenCheckUpkeepReturnsTrue()
        public
        runSingleRound
    {}

    function test_PerformUpkeepRevertsWhenCheckUpkeepReturnsFalse() public {
        uint256 currentBalance = 0;
        uint256 currentPlayers = 0;

        bytes memory upkeepNotNeededError = abi.encodeWithSelector(
            Raffle.Raffle__UpkeepNotNeeded.selector,
            currentBalance,
            currentPlayers,
            Raffle.RaffleState.OPEN
        );
        vm.expectRevert(upkeepNotNeededError);
        raffle.performUpkeep("");
    }

    function test_PerformUpkeepUpdatesRaffleState() public enterRaffle {
        vm.recordLogs();
        raffle.performUpkeep("");

        Vm.Log[] memory entries = vm.getRecordedLogs();
        (
            uint256 requestId,
            uint256 preSeed,
            uint16 minConfirmations,
            uint32 callbackGasLimit,
            uint32 numWords,
            bytes memory extraArgs
        ) = abi.decode(
                entries[0].data,
                (uint256, uint256, uint16, uint32, uint32, bytes)
            );

        assert(Raffle.RaffleState.CLOSE == raffle.getRaffleState());
        assert(uint256(requestId) > 0);
    }

    function test_FulfillRandomWordsIsCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public enterRaffle skipFork {
        vm.expectRevert();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function test_FulfillRandomWordsPicksWinnerResetsStateAndSendsReward()
        public
        skipFork
    {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        uint160 startingIndex = 1;
        uint256 nPlayers = 5;
        for (uint160 i = startingIndex; i <= nPlayers; i++) {
            address p = address(i);
            hoax(p, STARTING_USER_BALANCE);
            raffle.enter{value: entranceFee}();
        }
        uint256 previousTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = (nPlayers - 1) * entranceFee;

        vm.recordLogs();
        raffle.performUpkeep("");

        Vm.Log[] memory entries = vm.getRecordedLogs();
        (uint256 requestId, , , , , ) = abi.decode(
            entries[0].data,
            (uint256, uint256, uint16, uint32, uint32, bytes)
        );

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            requestId,
            address(raffle)
        );

        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getNumberOfPlayers() == 0);
        assert(previousTimeStamp < raffle.getLastTimeStamp());
        assert(
            raffle.getRecentWinner().balance ==
                STARTING_USER_BALANCE - entranceFee + prize
        );
    }

    // Helpers
    function _enterRaffle() public {
        vm.prank(player);
        raffle.enter{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
    }

    modifier enterRaffle() {
        _enterRaffle();
        _;
    }

    modifier runSingleRound() {
        _enterRaffle();
        raffle.performUpkeep("");
        _;
    }

    modifier skipFork() {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            return;
        }
        _;
    }
}
