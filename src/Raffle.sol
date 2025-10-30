// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import {VRFConsumerBaseV2Plus} from "lib/@chainlink/contracts@1.5.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

import {VRFConsumerBaseV2Plus} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

// import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle__notEnoughEathToRaffle();
    error Raffle__transferFailed();
    error Raffle__raffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playerLength, uint256 raffleState);
    // type declaration // enum
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1
    }
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFees;
    // @dev : The duratuon of the lottery in second
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    address private s_recentwinner;
    uint256 private s_lasttimeStamp;
    RaffleState private s_raffleState;

    // Events

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFees,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFees = entranceFees;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        // s_vrfCoordinator.requestRandomWords();
        s_lasttimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFees, "Not  enough ETH sent");
        if (msg.value < i_entranceFees) {
            revert Raffle__notEnoughEathToRaffle();
        }
        if(s_raffleState == RaffleState.OPEN) {
            revert Raffle__raffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    // automation 

    function checkUpkeep ( bytes memory /* checkData */) public view returns ( bool upkeepNeeded, bytes memory /* performData */)
    {
        bool timeHasPassed = (block.timestamp - s_lasttimeStamp) >= i_interval ;
        bool isOPen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0 ;
        bool hasPlayers = s_players.length > 0 ;
        upkeepNeeded = timeHasPassed && isOPen && hasBalance && hasPlayers ;
        return (upkeepNeeded , "");
        
    }
     
    function performUpkeep( bytes calldata /* performData */) external {

      (bool upkeepNeeded ,) = checkUpkeep("");
      if(!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState) );
        }

        s_raffleState = RaffleState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
         s_vrfCoordinator.requestRandomWords(request);

        //         requestId = s_vrfCoordinator.requestRandomWords(
        //     VRFV2PlusClient.RandomWordsRequest({
        //         keyHash: s_keyHash,
        //         subId: s_subscriptionId,
        //         requestConfirmations: requestConfirmations,
        //         callbackGasLimit: callbackGasLimit,
        //         numWords: numWords,
        //         extraArgs: VRFV2PlusClient._argsToBytes(
        //             // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
        //             VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
        //         )
        //     })
        // );
    }

    function fulfillRandomWords(
        uint256 /*requestId */,
        uint256[] calldata randomWords
    ) internal virtual override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentwinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lasttimeStamp = block.timestamp;
        emit WinnerPicked(s_recentwinner);
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__transferFailed();
        }
    }

    function getEntranceFees() external view returns (uint256) {
        return i_entranceFees;
    }

    function getRaffleState() external view returns(RaffleState) {
        return s_raffleState;
    }
}
