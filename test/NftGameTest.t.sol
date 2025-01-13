// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {NftGame} from "src/NftGame.sol";
import {DeployNftGame} from "script/DeployNftGame.s.sol";

contract NftGameTest is Test {
    DeployNftGame public deployer;
    NftGame nftGame;
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
        nftGame = deployer.run();
        vm.deal(USER, STARTING_BALANCE);
        vm.deal(USER_2, STARTING_BALANCE);
    }

    modifier characterNftMinted() {
        vm.startPrank(USER);
        nftGame.mintNft(CHARACTER_1_INDEX);
        _;
        vm.stopPrank();
    }

    // constructor
    function testConstructorInitializersCharacters() public view {
        NftGame.CharacterAttributes[] memory characters = nftGame.getCharacters();
        NftGame.CharacterAttributes[] memory deployerCharacters = deployer.getCharacters();
        NftGame.BossAttributes memory boss = nftGame.getBoss();
        NftGame.BossAttributes memory deployerBoss = deployer.getBoss();
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
        assertEq(nftGame.balanceOf(USER), 1);
    }

    function testMintNftAssignsCharacterAttributes() public characterNftMinted {
        assertEq(nftGame.getMintedCharacterAttributes(0).characterIndex, CHARACTER_1_INDEX);
    }

    function testMintNftEmitsEvent() public {
        vm.prank(USER);
        vm.expectEmit(true, true, true, false, address(nftGame));
        emit CharacterNftMinted(USER, TOKEN_ID_0, CHARACTER_1_INDEX);
        nftGame.mintNft(CHARACTER_1_INDEX);
    }

    // tokenURI
    function testTokenURIReturnsTheCharacterAttributes() public characterNftMinted {
        string memory tokenURI = nftGame.tokenURI(TOKEN_ID_0);
        assertEq(tokenURI, CHARACTER_1_TOKEN_URI);
    }

    // attack
    function testAttackFailsIfNotOwner() public {
        vm.prank(USER);
        nftGame.mintNft(CHARACTER_0_INDEX);
        vm.prank(USER_2);
        nftGame.mintNft(CHARACTER_1_INDEX);

        vm.prank(USER);
        vm.expectRevert(NftGame.NftGame_CantAttackIfNotOwner.selector);
        nftGame.attack(TOKEN_ID_1);
    }

    function testAttackWorksIfApproved() public {
        vm.startPrank(USER);
        nftGame.mintNft(CHARACTER_1_INDEX);
        nftGame.approve(USER_2, TOKEN_ID_0);
        vm.stopPrank();
        vm.startPrank(USER_2);
        NftGame.CharacterAttributes memory character = nftGame.getMintedCharacterAttributes(TOKEN_ID_0);
        NftGame.BossAttributes memory boss = nftGame.getBoss();
        vm.expectEmit(true, true, true, false, address(nftGame));
        emit AttackRoundComplete(
            TOKEN_ID_0, boss.currentHp - character.attackDamage, character.currentHp - boss.attackDamage
        );
        nftGame.attack(TOKEN_ID_0);
        vm.stopPrank();
    }

    function testAttackFailsIfCharacterHasNoHpLeft() public characterNftMinted {
        nftGame.attack(TOKEN_ID_0);
        nftGame.attack(TOKEN_ID_0);
        vm.expectRevert(NftGame.NftGame__CharacterHasNoHpLeft.selector);
        nftGame.attack(TOKEN_ID_0);
    }

    function testAttackFailsIfBossHasNoHpLeft() public {
        vm.startPrank(USER);
        nftGame.mintNft(CHARACTER_0_INDEX);
        nftGame.attack(TOKEN_ID_0);
        nftGame.attack(TOKEN_ID_0);
        vm.expectRevert(NftGame.NftGame__BossHasNoHpLeft.selector);
        nftGame.attack(TOKEN_ID_0);
        vm.stopPrank();
    }

    function testAttackModifiesCharacterAndBossHp() public characterNftMinted {
        NftGame.CharacterAttributes memory character = nftGame.getMintedCharacterAttributes(TOKEN_ID_0);
        uint256 previousCharacterHp = character.currentHp;
        NftGame.BossAttributes memory boss = nftGame.getBoss();
        uint256 previousBossHp = boss.currentHp;
        nftGame.attack(TOKEN_ID_0);
        assertEq(nftGame.getBoss().currentHp, previousBossHp - character.attackDamage);
        assertEq(nftGame.getMintedCharacterAttributes(TOKEN_ID_0).currentHp, previousCharacterHp - boss.attackDamage);
    }

    function testAttackNftEmitsEvent() public characterNftMinted {
        NftGame.CharacterAttributes memory character = nftGame.getMintedCharacterAttributes(TOKEN_ID_0);
        NftGame.BossAttributes memory boss = nftGame.getBoss();
        vm.expectEmit(true, true, true, false, address(nftGame));
        emit AttackRoundComplete(
            TOKEN_ID_0, boss.currentHp - character.attackDamage, character.currentHp - boss.attackDamage
        );
        nftGame.attack(TOKEN_ID_0);
    }
}
