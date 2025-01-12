// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract NftGame is ERC721 {
    using Strings for uint256;

    uint256 private s_tokenCounter;
    mapping(uint256 => CharacterAttributes) private s_tokenIdCharacterAttributes;
    CharacterAttributes[] private s_characters;
    BossAttributes private s_boss;

    event CharacterNftMinted(address indexed owner, uint256 indexed tokenId, uint256 indexed characterIndex);

    struct CharacterAttributes {
        uint256 characterIndex;
        string description;
        string name;
        string imageURI;
        uint256 hp;
        uint256 attackDamage;
    }

    struct BossAttributes {
        string name;
        string description;
        string imageURI;
        uint256 hp;
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
                hp: characters[i].hp,
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
                        chracterAttributes.hp.toString(),
                        '}, { "trait_type": "Attack Damage", "value": ',
                        chracterAttributes.attackDamage.toString(),
                        "} ]}"
                    )
                )
            )
        );
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
