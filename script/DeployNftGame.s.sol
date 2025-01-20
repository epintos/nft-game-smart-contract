// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { Script } from "forge-std/Script.sol";
import { NFTGame } from "src/NFTGame.sol";

contract DeployNFTGame is Script {
    NFTGame public NFTGame;

    NFTGame.CharacterAttributes[] public CHARACTERS;
    NFTGame.BossAttributes public BOSS = NFTGame.BossAttributes({
        description: "An undead king with a cursed sword",
        name: "Undead King",
        imageURI: "ipfs://QmdHgPwBnmwnCF3uF5Xh99BGg1HaL9ULme3EmP6VYc2KYK",
        currentHp: 400,
        maxHp: 400,
        attackDamage: 150
    });

    function run() external returns (NFTGame) {
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
        vm.startBroadcast();
        NFTGame = new NFTGame(CHARACTERS, BOSS);
        vm.stopBroadcast();
        return NFTGame;
    }

    function getCharacters() external view returns (NFTGame.CharacterAttributes[] memory) {
        return CHARACTERS;
    }

    function getBoss() external view returns (NFTGame.BossAttributes memory) {
        return BOSS;
    }
}
