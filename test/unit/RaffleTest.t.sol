// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test} from "forge-std/src/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelpefConfig.s.sol";
import {Raffle} from "../../script/DeployRaffle.s.sol";

contract RaffleContract is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;
    address public PLAYER = makeAddr("player");
    uint256 entranceFees;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;
    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFees = config.entranceFees;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;
    }

    function testRaffleInitializesInOpenState() public view  {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);


    }
}
