// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/src/Script.sol";

abstract contract CodeConstants {
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

    function getSepoliaEathConfig () public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFees: 0.01 ether ,
            interval: 30 ,// 30 seconds,
            vrfCoordinator: 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61 ,
            gasLane: 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be ,
            callbackGasLimit: 50000 , // for 5000.00 gas
            subscriptionId: 0
        });
    }

    function getOrCreateAnvilEthConfig () public  returns(NetworkConfig memory) {
        if(localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

    }
}
