// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { Script } from "forge-std/Script.sol";
import { NFTGame } from "src/NFTGame.sol";
import { HelperConfig } from "script/HelperConfig.s.sol";
import { CreateSubscription, FundSubscription, AddConsumer } from "script/Interactions.s.sol";

contract DeployNFTGame is Script {
    NFTGame public nftGame;

    NFTGame.CharacterAttributes[] public CHARACTERS;
    string[] public CHARACTER_NAMES = ["Hero", "Dark Wizard", "Fallen Hero"];
    string[] public CHARACTER_DESCRIPTIONS = [
        "A warrior with a heart of gold",
        "A dark wizard with a mysterious past",
        "A fallen hero with no remaining strength"
    ];
    string[] public CHARACTERS_IMAGES_URIS = [
        "ipfs://QmSfiFakNiceAjUyE3X2ijKrXcQ6YNG9aFkiUVh9jRYUBY",
        "ipfs://QmQx1cTtRWuPWGdgcN7i6nmVhuSpzvwYC2tZto8ojhrSgu",
        "ipfs://QmdHgPwBnmwnCF3uF5Xh99BGg1HaL9ULme3EmP6VYc2KYK"
    ];
    uint256[] public CHARACTER_CURRENT_HP = [500, 200, 0];
    uint256[] public CHARACTER_MAX_HP = [500, 200, 300];
    uint256[] public CHARACTER_ATTACK_DAMAGE = [300, 150, 100];

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
            CHARACTER_DESCRIPTIONS,
            CHARACTER_NAMES,
            CHARACTERS_IMAGES_URIS,
            CHARACTER_CURRENT_HP,
            CHARACTER_MAX_HP,
            CHARACTER_ATTACK_DAMAGE,
            BOSS,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        // Add consumer
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(nftGame), config.vrfCoordinator, config.subscriptionId, config.account);

        return (nftGame, helperConfig);
    }

    function getBoss() external view returns (NFTGame.BossAttributes memory) {
        return BOSS;
    }
}
