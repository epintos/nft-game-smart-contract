// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { Script } from "forge-std/Script.sol";
import { NFTGame } from "src/NFTGame.sol";
import { HelperConfig } from "script/HelperConfig.s.sol";
import { CreateSubscription, FundSubscription, AddConsumer } from "script/Interactions.s.sol";

contract DeployNFTGame is Script {
    NFTGame public nftGame;

    NFTGame.CharacterAttributes[] public CHARACTERS;
    NFTGame.BossAttributes public BOSS = NFTGame.BossAttributes({
        description: "An undead king with a cursed sword",
        name: "Undead King",
        imageURI: "ipfs://QmdHgPwBnmwnCF3uF5Xh99BGg1HaL9ULme3EmP6VYc2KYK",
        currentHp: 400,
        maxHp: 400,
        attackDamage: 150
    });

    function run() external returns (NFTGame, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        buildCharacters();

        if (config.subscriptionId == 0) {
            // Create subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) =
                createSubscription.createSubscription(config.vrfCoordinator, config.account);

            // Fund it
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link, config.account);
        }

        vm.startBroadcast();
        nftGame = new NFTGame(
            CHARACTERS, BOSS, config.vrfCoordinator, config.gasLane, config.subscriptionId, config.callbackGasLimit
        );
        vm.stopBroadcast();

        // Add consumer
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(nftGame), config.vrfCoordinator, config.subscriptionId, config.account);

        return (nftGame, helperConfig);
    }

    function getCharacters() external view returns (NFTGame.CharacterAttributes[] memory) {
        return CHARACTERS;
    }

    function getBoss() external view returns (NFTGame.BossAttributes memory) {
        return BOSS;
    }

    function buildCharacters() internal {
        CHARACTERS.push(
            NFTGame.CharacterAttributes({
                characterIndex: 0,
                description: "A warrior with a heart of gold",
                name: "Hero",
                imageURI: "ipfs://QmSfiFakNiceAjUyE3X2ijKrXcQ6YNG9aFkiUVh9jRYUBY",
                currentHp: 500,
                maxHp: 500,
                attackDamage: 300
            })
        );
        CHARACTERS.push(
            NFTGame.CharacterAttributes({
                characterIndex: 1,
                description: "A dark wizard with a mysterious past",
                name: "Dark Wizard",
                imageURI: "ipfs://QmQx1cTtRWuPWGdgcN7i6nmVhuSpzvwYC2tZto8ojhrSgu",
                currentHp: 200,
                maxHp: 200,
                attackDamage: 150
            })
        );
        CHARACTERS.push(
            NFTGame.CharacterAttributes({
                characterIndex: 2,
                description: "A fallen hero with no remaining strength",
                name: "Fallen Hero",
                imageURI: "ipfs://QmdHgPwBnmwnCF3uF5Xh99BGg1HaL9ULme3EmP6VYc2KYK",
                currentHp: 0,
                maxHp: 300,
                attackDamage: 100
            })
        );
    }
}
