// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { Test, console2 } from "forge-std/Test.sol";
import { NFTGame } from "src/NFTGame.sol";
import { DeployNFTGame } from "script/DeployNFTGame.s.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import { CodeConstants, HelperConfig } from "script/HelperConfig.s.sol";
import { Vm } from "forge-std/Vm.sol";

contract NFTGameTest is Test {
    DeployNFTGame public deployer;
    NFTGame public nftGame;
    HelperConfig public helperConfig;
    address USER = makeAddr("USER");
    address USER_2 = makeAddr("USER_2");
    uint256 STARTING_BALANCE = 10 ether;
    string constant CHARACTER_1_TOKEN_URI =
        "data:application/json;base64,eyJuYW1lIjogIkRhcmsgV2l6YXJkIiwgImRlc2NyaXB0aW9uIjogIkEgZGFyayB3aXphcmQgd2l0aCBhIG15c3RlcmlvdXMgcGFzdCIsICJpbWFnZSI6ICJpcGZzOi8vUW1ReDFjVHRSV3VQV0dkZ2NON2k2bm1WaHVTcHp2d1lDMnRadG84b2poclNndSIsICJhdHRyaWJ1dGVzIjogWyB7ICJ0cmFpdF90eXBlIjogIkhlYWx0aCBQb2ludHMiLCAidmFsdWUiOiAyMDB9LCB7ICJ0cmFpdF90eXBlIjogIk1heCBIZWFsdGggUG9pbnRzIiwgInZhbHVlIjogMjAwfSwgeyAidHJhaXRfdHlwZSI6ICJBdHRhY2sgRGFtYWdlIiwgInZhbHVlIjogMTUwfSBdfQ==";
    uint256 constant CHARACTER_0_INDEX = 0;
    uint256 constant CHARACTER_1_INDEX = 1;
    uint256 constant CHARACTER_2_INDEX = 2;
    uint256 constant TOKEN_ID_0 = 0;
    uint256 constant TOKEN_ID_1 = 1;
    uint256 constant RANDOM_WORD_GENERATED_1 =
        78_541_660_797_044_910_968_829_902_406_342_334_108_369_226_379_826_116_161_446_442_989_268_089_806_461;
    uint256 constant RANDOM_WORD_GENERATED_2 =
        92_458_281_274_488_595_289_803_937_127_152_923_398_167_637_295_201_432_141_969_818_930_235_769_911_599;

    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;

    event CharacterNftMinted(address indexed owner, uint256 indexed tokenId, uint256 indexed characterIndex);
    event AttackRoundComplete(uint256 indexed tokenId, uint256 indexed bossHpLeft, uint256 indexed characterHpLeft);
    event RequestedRandomAttackDamage(uint256 indexed requestId);

    function setUp() public {
        deployer = new DeployNFTGame();
        (nftGame, helperConfig) = deployer.run();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;
        vm.deal(USER, STARTING_BALANCE);
        vm.deal(USER_2, STARTING_BALANCE);
    }

    modifier characterNFTMinted() {
        vm.startPrank(USER);
        nftGame.mintNFT(CHARACTER_1_INDEX);
        _;
        vm.stopPrank();
    }

    // constructor
    function testConstructorInitializersCharacters() public view {
        NFTGame.CharacterAttributes[] memory characters = nftGame.getCharacters();
        NFTGame.CharacterAttributes[] memory deployerCharacters = deployer.getCharacters();
        NFTGame.BossAttributes memory boss = nftGame.getBoss();
        NFTGame.BossAttributes memory deployerBoss = deployer.getBoss();
        assertEq(characters.length, 3);
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

    // mintNFT
    function testmintNFTMintsNftToUser() public characterNFTMinted {
        assertEq(nftGame.balanceOf(USER), 1);
    }

    function testmintNFTAssignsCharacterAttributes() public characterNFTMinted {
        assertEq(nftGame.getMintedCharacterAttributes(0).characterIndex, CHARACTER_1_INDEX);
    }

    function testmintNFTEmitsEvent() public {
        vm.prank(USER);
        vm.expectEmit(true, true, true, false, address(nftGame));
        emit CharacterNftMinted(USER, TOKEN_ID_0, CHARACTER_1_INDEX);
        nftGame.mintNFT(CHARACTER_1_INDEX);
    }

    // tokenURI
    function testTokenURIReturnsTheCharacterAttributes() public characterNFTMinted {
        string memory tokenURI = nftGame.tokenURI(TOKEN_ID_0);
        assertEq(tokenURI, CHARACTER_1_TOKEN_URI);
    }

    // attack
    function testAttackFailsIfNotOwner() public {
        vm.prank(USER);
        nftGame.mintNFT(CHARACTER_0_INDEX);
        vm.prank(USER_2);
        nftGame.mintNFT(CHARACTER_1_INDEX);

        vm.prank(USER);
        vm.expectRevert(NFTGame.NFTGame_CantAttackIfNotOwner.selector);
        nftGame.attack(TOKEN_ID_1);
    }

    function testAttackRequestsRandomNumbersIfApproved() public {
        vm.startPrank(USER);
        nftGame.mintNFT(CHARACTER_1_INDEX);
        nftGame.approve(USER_2, TOKEN_ID_0);
        vm.stopPrank();
        vm.startPrank(USER_2);
        vm.recordLogs();
        nftGame.attack(TOKEN_ID_0);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1]; // 0 would be the one emited by the vrf contract
        assert(uint256(requestId) > 0);
        vm.stopPrank();
    }

    function testAttackFailsIfCharacterHasNoHpLeft() public {
        vm.startPrank(USER);
        nftGame.mintNFT(CHARACTER_2_INDEX); // Character without HP Left
        vm.expectRevert(NFTGame.NFTGame__CharacterHasNoHpLeft.selector);
        nftGame.attack(TOKEN_ID_0);
        vm.stopPrank();
    }
    // TODO
    // function testAttackFailsIfBossHasNoHpLeft() public { }

    // fulfillRandomWords
    function testFulfillRandomWordsAttacks() public characterNFTMinted {
        NFTGame.CharacterAttributes memory oldCharacterState = nftGame.getMintedCharacterAttributes(TOKEN_ID_0);
        NFTGame.BossAttributes memory oldBossState = nftGame.getBoss();

        vm.startPrank(USER);
        nftGame.mintNFT(CHARACTER_1_INDEX);
        vm.recordLogs();
        nftGame.attack(TOKEN_ID_0);
        vm.stopPrank();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(nftGame));
        NFTGame.CharacterAttributes memory character = nftGame.getMintedCharacterAttributes(TOKEN_ID_0);
        NFTGame.BossAttributes memory boss = nftGame.getBoss();
        assert(oldCharacterState.currentHp > character.currentHp);
        assert(oldBossState.currentHp > boss.currentHp);
    }

    function testFulfillRandomWordsEmitsEvent() public characterNFTMinted {
        NFTGame.CharacterAttributes memory oldCharacterState = nftGame.getMintedCharacterAttributes(TOKEN_ID_0);
        NFTGame.BossAttributes memory oldBossState = nftGame.getBoss();

        vm.startPrank(USER);
        nftGame.mintNFT(CHARACTER_1_INDEX);
        vm.recordLogs();
        nftGame.attack(TOKEN_ID_0);
        vm.stopPrank();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 characterAttack = RANDOM_WORD_GENERATED_1 % oldCharacterState.attackDamage + 1;
        uint256 bossAttack = RANDOM_WORD_GENERATED_2 % oldBossState.attackDamage + 1;
        vm.expectEmit(true, true, true, false, address(nftGame));
        emit AttackRoundComplete(
            TOKEN_ID_0, oldBossState.currentHp - characterAttack, oldCharacterState.currentHp - bossAttack
        );
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(nftGame));
    }
}
