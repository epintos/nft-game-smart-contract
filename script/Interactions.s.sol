// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { console2, Script } from "forge-std/Script.sol";
import { NFTGame } from "src/NFTGame.sol";
import { DevOpsTools } from "lib/foundry-devops/src/DevOpsTools.sol";
import { HelperConfig, CodeConstants } from "script/HelperConfig.s.sol";
import { LinkToken } from "@chainlink/contracts/src/v0.8/shared/token/ERC677/LinkToken.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract MintNFT is Script {
    NFTGame public nftGame;

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("NFTGame", block.chainid);
        uint256 characterIndex = vm.envUint("CHARACTER_INDEX");
        mint(mostRecentlyDeployed, characterIndex);
    }

    function mint(address mostRecentlyDeploy, uint256 characterIndex) public {
        vm.startBroadcast();
        NFTGame(mostRecentlyDeploy).mintNFT(characterIndex);
        vm.stopBroadcast();
    }
}

contract AttackNFT is Script {
    NFTGame public nftGame;

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("NFTGame", block.chainid);
        uint256 tokenId = vm.envUint("TOKEN_ID");
        attack(mostRecentlyDeployed, tokenId);
    }

    function attack(address mostRecentlyDeploy, uint256 tokenId) public {
        vm.startBroadcast();
        NFTGame(mostRecentlyDeploy).attack(tokenId);
        vm.stopBroadcast();
    }
}

contract CreateSubscription is Script, CodeConstants {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId,) = createSubscription(vrfCoordinator, helperConfig.getConfig().account);
        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address) {
        console2.log("Creating subscription on chainId: ", block.chainid);
        console2.log("Creating subscription on acount: ", account);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console2.log("Your subscription Id is: ", subId);
        console2.log("Please update the subscription Id in your HelperConfig.s.sol");
        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        fundSubscription(vrfCoordinator, subscriptionId, linkToken, helperConfig.getConfig().account);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId,
        address linkToken,
        address account
    )
        public
    {
        console2.log("Funding subscription: ", subscriptionId);
        console2.log("Using vrfCoordinator: ", vrfCoordinator);
        console2.log("On ChainId: ", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId, helperConfig.getConfig().account);
    }

    function addConsumer(address contractToAddtoVrf, address vrfCoordinator, uint256 subId, address account) public {
        console2.log("Adding consumer contract", contractToAddtoVrf);
        console2.log("To vrfCoordinator", vrfCoordinator);
        console2.log("On ChainId", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddtoVrf);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("NFTGame", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
