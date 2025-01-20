// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { console2, Script } from "forge-std/Script.sol";
import { NFTGame } from "src/NFTGame.sol";
import { DevOpsTools } from "lib/foundry-devops/src/DevOpsTools.sol";

contract MintNFT is Script {
    NFTGame public NFTGame;

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("NFTGame", block.chainid);
        uint256 characterIndex = vm.envUint("CHARACTER_INDEX");
        mint(mostRecentlyDeployed, characterIndex);
    }

    function mint(address mostRecentlyDeploy, uint256 characterIndex) public {
        vm.startBroadcast();
        NFTGame(mostRecentlyDeploy).mintNft(characterIndex);
        vm.stopBroadcast();
    }
}

contract AttackNFT is Script {
    NFTGame public NFTGame;

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
