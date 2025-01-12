// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {NftGame} from "src/NftGame.sol";
import {DeployNftGame} from "script/DeployNftGame.s.sol";
import {console2, Script} from "forge-std/Script.sol";


contract NftGameTest is Test {
    DeployNftGame public deployer;
    NftGame nftGame;
    address USER  = makeAddr("USER");
    uint256 STARTING_BALANCE = 10 ether;
    string constant CHARACTER_1_TOKEN_URI = "data:application/json;base64,eyJuYW1lIjogIkRhcmsgV2l6YXJkIiwgImRlc2NyaXB0aW9uIjogIkEgZGFyayB3aXphcmQgd2l0aCBhIG15c3RlcmlvdXMgcGFzdCIsICJpbWFnZSI6ICJpcGZzOi8vUW1ReDFjVHRSV3VQV0dkZ2NON2k2bm1WaHVTcHp2d1lDMnRadG84b2poclNndSIsICJhdHRyaWJ1dGVzIjogWyB7ICJ0cmFpdF90eXBlIjogIkhlYWx0aCBQb2ludHMiLCAidmFsdWUiOiAyMDB9LCB7ICJ0cmFpdF90eXBlIjogIkF0dGFjayBEYW1hZ2UiLCAidmFsdWUiOiAxNTB9IF19";
    uint256 constant CHARACTER_1_INDEX = 1;

    function setUp() public {
        deployer = new DeployNftGame();
        nftGame = deployer.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testConstructorInitializersCharacters() public view {
        NftGame.CharacterAttributes[] memory characters = nftGame.getCharacters();
        NftGame.CharacterAttributes[] memory deployerCharacters = deployer.getCharacters();
        NftGame.BossAttributes memory boss = nftGame.getBoss();
        NftGame.BossAttributes memory deployerBoss = deployer.getBoss();
        assertEq(characters.length, 2);
        for(uint256 i = 0; i < characters.length; i++) {
            assertEq(characters[i].characterIndex, deployerCharacters[i].characterIndex);
            assertEq(characters[i].description, deployerCharacters[i].description);
            assertEq(characters[i].name, deployerCharacters[i].name);
            assertEq(characters[i].imageURI, deployerCharacters[i].imageURI);
            assertEq(characters[i].hp, deployerCharacters[i].hp);
            assertEq(characters[i].attackDamage, deployerCharacters[i].attackDamage);
        }
        assertEq(boss.description, deployerBoss.description);
        assertEq(boss.name, deployerBoss.name);
        assertEq(boss.imageURI, deployerBoss.imageURI);
        assertEq(boss.hp, deployerBoss.hp);
        assertEq(boss.attackDamage, deployerBoss.attackDamage);
    }

    function testMintsNftToUser() public {
        vm.prank(USER);
        nftGame.mintNft(CHARACTER_1_INDEX);
        assertEq(nftGame.balanceOf(USER), 1);
    }

    function testMintsCharacterAttributes() public {
        vm.prank(USER);
        nftGame.mintNft(CHARACTER_1_INDEX);
        assertEq(nftGame.getMintedCharacterAttributes(0).characterIndex, CHARACTER_1_INDEX);
    }

    function testTokenURIReturnsTheCharacterAttributes() public {
        vm.prank(USER);
        nftGame.mintNft(CHARACTER_1_INDEX);
        string memory tokenURI = nftGame.tokenURI(0);
        assertEq(tokenURI, CHARACTER_1_TOKEN_URI);
    }
}
