// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import { NFTGame } from "src/NFTGame.sol";
import { DeployNftGame } from "script/DeployNftGame.s.sol";

contract NftGameTest is Test {
    DeployNftGame public deployer;
    NFTGame NFTGame;
    address USER = makeAddr("USER");
    address USER_2 = makeAddr("USER_2");
    uint256 STARTING_BALANCE = 10 ether;
    string constant CHARACTER_1_TOKEN_URI =
        "data:application/json;base64,eyJuYW1lIjogIkRhcmsgV2l6YXJkIiwgImRlc2NyaXB0aW9uIjogIkEgZGFyayB3aXphcmQgd2l0aCBhIG15c3RlcmlvdXMgcGFzdCIsICJpbWFnZSI6ICJpcGZzOi8vUW1ReDFjVHRSV3VQV0dkZ2NON2k2bm1WaHVTcHp2d1lDMnRadG84b2poclNndSIsICJhdHRyaWJ1dGVzIjogWyB7ICJ0cmFpdF90eXBlIjogIkhlYWx0aCBQb2ludHMiLCAidmFsdWUiOiAyMDB9LCB7ICJ0cmFpdF90eXBlIjogIk1heCBIZWFsdGggUG9pbnRzIiwgInZhbHVlIjogMjAwfSwgeyAidHJhaXRfdHlwZSI6ICJBdHRhY2sgRGFtYWdlIiwgInZhbHVlIjogMTUwfSBdfQ==";
    uint256 constant CHARACTER_0_INDEX = 0;
    uint256 constant CHARACTER_1_INDEX = 1;
    uint256 constant TOKEN_ID_0 = 0;
    uint256 constant TOKEN_ID_1 = 1;

    event CharacterNftMinted(address indexed owner, uint256 indexed tokenId, uint256 indexed characterIndex);
    event AttackRoundComplete(uint256 indexed tokenId, uint256 indexed bossHpLeft, uint256 indexed characterHpLeft);

    function setUp() public {
        deployer = new DeployNftGame();
        NFTGame = deployer.run();
        vm.deal(USER, STARTING_BALANCE);
        vm.deal(USER_2, STARTING_BALANCE);
    }

    modifier characterNftMinted() {
        vm.startPrank(USER);
        NFTGame.mintNft(CHARACTER_1_INDEX);
        _;
        vm.stopPrank();
    }

    // constructor
    function testConstructorInitializersCharacters() public view {
        NFTGame.CharacterAttributes[] memory characters = NFTGame.getCharacters();
        NFTGame.CharacterAttributes[] memory deployerCharacters = deployer.getCharacters();
        NFTGame.BossAttributes memory boss = NFTGame.getBoss();
        NFTGame.BossAttributes memory deployerBoss = deployer.getBoss();
        assertEq(characters.length, 2);
        for (uint256 i = 0; i < characters.length; i++) {
            assertEq(characters[i].characterIndex, deployerCharacters[i].characterIndex);
            assertEq(characters[i].description, deployerCharacters[i].description);
            assertEq(characters[i].name, deployerCharacters[i].name);
            assertEq(characters[i].imageURI, deployerCharacters[i].imageURI);
            assertEq(characters[i].currentHp, deployerCharacters[i].currentHp);
            assertEq(characters[i].maxHp, deployerCharacters[i].maxHp);
            assertEq(characters[i].attackDamage, deployerCharacters[i].attackDamage);
        }
        assertEq(boss.description, deployerBoss.description);
        assertEq(boss.name, deployerBoss.name);
        assertEq(boss.imageURI, deployerBoss.imageURI);
        assertEq(boss.currentHp, deployerBoss.currentHp);
        assertEq(boss.maxHp, deployerBoss.maxHp);
        assertEq(boss.attackDamage, deployerBoss.attackDamage);
    }

    // mintNft
    function testMintNftMintsNftToUser() public characterNftMinted {
        assertEq(NFTGame.balanceOf(USER), 1);
    }

    function testMintNftAssignsCharacterAttributes() public characterNftMinted {
        assertEq(NFTGame.getMintedCharacterAttributes(0).characterIndex, CHARACTER_1_INDEX);
    }

    function testMintNftEmitsEvent() public {
        vm.prank(USER);
        vm.expectEmit(true, true, true, false, address(NFTGame));
        emit CharacterNftMinted(USER, TOKEN_ID_0, CHARACTER_1_INDEX);
        NFTGame.mintNft(CHARACTER_1_INDEX);
    }

    // tokenURI
    function testTokenURIReturnsTheCharacterAttributes() public characterNftMinted {
        string memory tokenURI = NFTGame.tokenURI(TOKEN_ID_0);
        assertEq(tokenURI, CHARACTER_1_TOKEN_URI);
    }

    // attack
    function testAttackFailsIfNotOwner() public {
        vm.prank(USER);
        NFTGame.mintNft(CHARACTER_0_INDEX);
        vm.prank(USER_2);
        NFTGame.mintNft(CHARACTER_1_INDEX);

        vm.prank(USER);
        vm.expectRevert(NFTGame.NftGame_CantAttackIfNotOwner.selector);
        NFTGame.attack(TOKEN_ID_1);
    }

    function testAttackWorksIfApproved() public {
        vm.startPrank(USER);
        NFTGame.mintNft(CHARACTER_1_INDEX);
        NFTGame.approve(USER_2, TOKEN_ID_0);
        vm.stopPrank();
        vm.startPrank(USER_2);
        NFTGame.CharacterAttributes memory character = NFTGame.getMintedCharacterAttributes(TOKEN_ID_0);
        NFTGame.BossAttributes memory boss = NFTGame.getBoss();
        vm.expectEmit(true, true, true, false, address(NFTGame));
        emit AttackRoundComplete(
            TOKEN_ID_0, boss.currentHp - character.attackDamage, character.currentHp - boss.attackDamage
        );
        NFTGame.attack(TOKEN_ID_0);
        vm.stopPrank();
    }

    function testAttackFailsIfCharacterHasNoHpLeft() public characterNftMinted {
        NFTGame.attack(TOKEN_ID_0);
        NFTGame.attack(TOKEN_ID_0);
        vm.expectRevert(NFTGame.NftGame__CharacterHasNoHpLeft.selector);
        NFTGame.attack(TOKEN_ID_0);
    }

    function testAttackFailsIfBossHasNoHpLeft() public {
        vm.startPrank(USER);
        NFTGame.mintNft(CHARACTER_0_INDEX);
        NFTGame.attack(TOKEN_ID_0);
        NFTGame.attack(TOKEN_ID_0);
        vm.expectRevert(NFTGame.NftGame__BossHasNoHpLeft.selector);
        NFTGame.attack(TOKEN_ID_0);
        vm.stopPrank();
    }

    function testAttackModifiesCharacterAndBossHp() public characterNftMinted {
        NFTGame.CharacterAttributes memory character = NFTGame.getMintedCharacterAttributes(TOKEN_ID_0);
        uint256 previousCharacterHp = character.currentHp;
        NFTGame.BossAttributes memory boss = NFTGame.getBoss();
        uint256 previousBossHp = boss.currentHp;
        NFTGame.attack(TOKEN_ID_0);
        assertEq(NFTGame.getBoss().currentHp, previousBossHp - character.attackDamage);
        assertEq(NFTGame.getMintedCharacterAttributes(TOKEN_ID_0).currentHp, previousCharacterHp - boss.attackDamage);
    }

    function testAttackNftEmitsEvent() public characterNftMinted {
        NFTGame.CharacterAttributes memory character = NFTGame.getMintedCharacterAttributes(TOKEN_ID_0);
        NFTGame.BossAttributes memory boss = NFTGame.getBoss();
        vm.expectEmit(true, true, true, false, address(NFTGame));
        emit AttackRoundComplete(
            TOKEN_ID_0, boss.currentHp - character.attackDamage, character.currentHp - boss.attackDamage
        );
        NFTGame.attack(TOKEN_ID_0);
    }
}
