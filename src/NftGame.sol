// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract NftGame is ERC721 {
    using Strings for uint256;

    error NftGame__CharacterHasNoHpLeft();
    error NftGame__BossHasNoHpLeft();
    error NftGame_CantAttackIfNotOwner();

    uint256 private s_tokenCounter;
    mapping(uint256 => CharacterAttributes) private s_tokenIdCharacterAttributes;
    CharacterAttributes[] private s_characters;
    BossAttributes private s_boss;

    event CharacterNftMinted(address indexed owner, uint256 indexed tokenId, uint256 indexed characterIndex);
    event AttackRoundComplete(uint256 indexed tokenId, uint256 indexed bossHpLeft, uint256 indexed characterHpLeft);

    struct CharacterAttributes {
        uint256 characterIndex;
        string description;
        string name;
        string imageURI;
        uint256 currentHp;
        uint256 maxHp;
        uint256 attackDamage;
    }

    struct BossAttributes {
        string name;
        string description;
        string imageURI;
        uint256 currentHp;
        uint256 maxHp;
        uint256 attackDamage;
    }

    constructor(CharacterAttributes[] memory characters, BossAttributes memory boss) ERC721("NFTGame", "NFTG") {
        s_boss = boss;
        for (uint256 i = 0; i < characters.length; i++) {
            CharacterAttributes memory character = CharacterAttributes({
                characterIndex: i,
                description: characters[i].description,
                name: characters[i].name,
                imageURI: characters[i].imageURI,
                currentHp: characters[i].currentHp,
                maxHp: characters[i].maxHp,
                attackDamage: characters[i].attackDamage
            });
            s_characters.push(character);
        }
    }

    function mintNft(uint256 characterIndex) external {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdCharacterAttributes[s_tokenCounter] = s_characters[characterIndex];
        emit CharacterNftMinted(msg.sender, s_tokenCounter, characterIndex);

        s_tokenCounter++;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        CharacterAttributes memory chracterAttributes = s_tokenIdCharacterAttributes[tokenId];
        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    abi.encodePacked(
                        '{"name": "',
                        chracterAttributes.name,
                        '", "description": "',
                        chracterAttributes.description,
                        '", "image": "',
                        chracterAttributes.imageURI,
                        '", "attributes": [ { "trait_type": "Health Points", "value": ',
                        chracterAttributes.currentHp.toString(),
                        '}, { "trait_type": "Max Health Points", "value": ',
                        chracterAttributes.maxHp.toString(),
                        '}, { "trait_type": "Attack Damage", "value": ',
                        chracterAttributes.attackDamage.toString(),
                        "} ]}"
                    )
                )
            )
        );
    }

    function attack(uint256 tokenId) external {
        if (getApproved(tokenId) != msg.sender && ownerOf(tokenId) != msg.sender) {
            revert NftGame_CantAttackIfNotOwner();
        }

        CharacterAttributes memory ownedCharacter = s_tokenIdCharacterAttributes[tokenId];
        if (ownedCharacter.currentHp == 0) {
            revert NftGame__CharacterHasNoHpLeft();
        }

        if (s_boss.currentHp == 0) {
            revert NftGame__BossHasNoHpLeft();
        }

        if (ownedCharacter.currentHp < s_boss.attackDamage) {
            ownedCharacter.currentHp = 0;
        } else {
            ownedCharacter.currentHp -= s_boss.attackDamage;
        }

        if (s_boss.currentHp < ownedCharacter.attackDamage) {
            s_boss.currentHp = 0;
        } else {
            s_boss.currentHp -= ownedCharacter.attackDamage;
        }

        s_tokenIdCharacterAttributes[tokenId] = ownedCharacter;

        emit AttackRoundComplete(tokenId, s_boss.currentHp, ownedCharacter.currentHp);
    }

    function getCharacters() public view returns (CharacterAttributes[] memory) {
        return s_characters;
    }

    function getBoss() public view returns (BossAttributes memory) {
        return s_boss;
    }

    function getMintedCharacterAttributes(uint256 tokenId) public view returns (CharacterAttributes memory) {
        return s_tokenIdCharacterAttributes[tokenId];
    }
}
