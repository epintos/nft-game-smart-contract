// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { console2, Script } from "forge-std/Script.sol";
import { NftGame } from "src/NftGame.sol";
import { DevOpsTools } from "lib/foundry-devops/src/DevOpsTools.sol";

contract MintNft is Script {
    NftGame public nftGame;

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("NftGame", block.chainid);
        uint256 characterIndex = vm.envUint("CHARACTER_INDEX");
        mint(mostRecentlyDeployed, characterIndex);
    }

    function mint(address mostRecentlyDeploy, uint256 characterIndex) public {
        vm.startBroadcast();
        NftGame(mostRecentlyDeploy).mintNft(characterIndex);
        vm.stopBroadcast();
    }
}

contract AttackNft is Script {
    NftGame public nftGame;

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("NftGame", block.chainid);
        uint256 tokenId = vm.envUint("TOKEN_ID");
        attack(mostRecentlyDeployed, tokenId);
    }

    function attack(address mostRecentlyDeploy, uint256 tokenId) public {
        vm.startBroadcast();
        NftGame(mostRecentlyDeploy).attack(tokenId);
        vm.stopBroadcast();
    }
}
