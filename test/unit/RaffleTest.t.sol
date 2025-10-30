// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test} from "forge-std/src/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelpefConfig.s.sol";
import {Raffle} from "../../script/DeployRaffle.s.sol";



contract RaffleContract is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;
    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
       (raffle,helperConfig) = deployer.deployContract();
    }
}