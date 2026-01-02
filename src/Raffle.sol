// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A Raffle Contract
 * @author meraf00
 * @notice A contract for creating a raffle game
 */
contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 nPlayers,
        RaffleState state
    );
    error Raffle__InsufficientBalance(uint256 available, uint256 required);
    error Raffle__TransferFailed();
    error Raffle__GameNotOpen();
    error Raffle__NoPlayers();

    enum RaffleState {
        OPEN,
        CLOSE
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_OF_WORDS = 1;

    uint256 private immutable i_interval; // in seconds
    uint256 private immutable i_entranceFee;

    bytes32 private immutable i_gasLane; // vrf key hash
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    RaffleState private s_raffleState;

    // Events
    event PlayerEntered(address indexed player);
    event WinnerSelected(address indexed player);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enter() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__InsufficientBalance(msg.value, i_entranceFee);
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__GameNotOpen();
        }

        s_players.push(payable(msg.sender));

        emit PlayerEntered(msg.sender);
    }

    /**
     * @dev Function checked by Chainlink Automation nodes
     */
    function checkUpkeep(
        bytes memory /* upkeepData */
    ) public view returns (bool, bytes memory /* performData */) {
        bool hasTimePassed = block.timestamp - s_lastTimestamp > i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        bool upkeepNeeded = hasTimePassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                s_raffleState
            );
        }

        s_raffleState = RaffleState.CLOSE;

        s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_OF_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
                )
            })
        );
    }

    function fulfillRandomWords(
        uint256,
        /* requestId */
        uint256[] calldata randomWords
    ) internal override {
        uint256 nPlayers = s_players.length;
        address payable winner = s_players[randomWords[0] % nPlayers];
        uint256 prizeAmount = (nPlayers - 1) * i_entranceFee;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;
        emit WinnerSelected(winner);

        (bool success, ) = winner.call{value: prizeAmount}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    // Getter Functions

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }
}
