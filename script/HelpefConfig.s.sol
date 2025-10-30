// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/src/Script.sol";
import {VRFCoordinatorV2_5Mock} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";


abstract contract CodeConstants {
/* VRF Mock values */
  uint96 public MOCK_BASE_FEES = 0.25 ether ;
  uint96 public MOCK_GAS_PRICE_LINK = 1e9;
  // LINK / ETH PRICE
  int256 public MOCK_WEI_PER_UNIT_LINK = 4e9;
  uint256 public constant ETH_SEPOLIA_CHAINID = 1115511;
  uint256 public constant LOCAL_CHAINID = 31337;
}

contract HelperConfig is CodeConstants , Script {
    error HelperConfig__InvalidChainId();
    struct NetworkConfig {
        uint256 entranceFees;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
    }
    NetworkConfig public localNetworkConfig ;
    mapping(uint256 chainid => NetworkConfig) public networkConfigs;

    constructor () {
        networkConfigs[ETH_SEPOLIA_CHAINID] = getSepoliaEathConfig();
    }

    function getConfigByChainid(uint256 chainId) public returns (NetworkConfig memory) {
        if(networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        }
        else if (chainId == LOCAL_CHAINID) {
           return getOrCreateAnvilEthConfig();

        }
        else revert HelperConfig__InvalidChainId();
    } 

    function getConfig() public returns (NetworkConfig memory) {
        getConfigByChainid(block.chainid);
    }

    function getSepoliaEathConfig () public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFees: 0.01 ether ,
            interval: 30 ,// 30 seconds,
            vrfCoordinator: 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61 ,
            gasLane: 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be ,
            subscriptionId: 0,
            callbackGasLimit: 50000 , // for 5000.00 gas

        });
    }

    function getOrCreateAnvilEthConfig () public  returns(NetworkConfig memory) {
        if(localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        // deploy mocks
        vm.startBroadcast();
         VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEES , MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK);
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFees: 0.01 ether ,
            interval: 30 ,// 30 seconds,
            vrfCoordinator: address(vrfCoordinatorMock) ,
            // doesnt matter
            gasLane: 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be ,
            // doesnt matter
            callbackGasLimit: 50000 , // for 5000.00 gas
            // we will fix it
            subscriptionId: 0
        });
        return localNetworkConfig;

    }
}
