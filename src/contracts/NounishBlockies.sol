// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import {INounsSeeder} from "./interfaces/INounsSeeder.sol";
import {MultiPartRLEToSVG} from "./libs/MultiPartRLEToSVG.sol";
import {NounsDescriptorV2} from "./NounsDescriptorV2.sol";
import {ISVGRenderer} from "./interfaces/ISVGRenderer.sol";
import {NFTDescriptorV2} from "./libs/NFTDescriptorV2.sol";

contract NouniesBlockies is ERC721 {
    using Counters for Counters.Counter;

    INounsSeeder public seeder;
    NounsDescriptorV2 public descriptor;

    Counters.Counter private _tokenIdCounter;

    error NoOwner();

    constructor(address _seeder, address _descriptor) ERC721("Blockies", "BLKS") {
        seeder = INounsSeeder(_seeder);
        descriptor = NounsDescriptorV2(_descriptor);
    }

    function safeMint() public payable {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId);
        // _safeMint(msg.sender, tokenId);
    }

    // Palette Index, Bounds [Top (Y), Right (X), Bottom (Y), Left (X)] (4 Bytes),
    // [Pixel Length (1 Byte), Color Index (1 Byte)][]
    function getHeadImage(uint256 tokenId) public view returns (bytes memory) {
        // if(owner == address(0)){
        //     error NoOwner();
        // }
        uint8[256] memory imagedata = createImageData(getTokenRandomness(tokenId));

        bytes memory headImage;

        headImage = bytes.concat(
            abi.encodePacked(uint8(0)), // palette
            abi.encodePacked(uint8(5)), // top
            abi.encodePacked(uint8(24)), // right
            abi.encodePacked(uint8(20)), // bottom
            abi.encodePacked(uint8(8)) // left
        );

        uint8[3] memory colors = createColors(getTokenRandomness(tokenId));

        for (uint256 i = 0; i < 256; i++) {
            headImage = bytes.concat(headImage, abi.encodePacked(uint8(1)), abi.encodePacked(colors[imagedata[i]]));
        }
        return headImage;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        INounsSeeder.Seed memory seed = getSeed(_tokenId);
        ISVGRenderer.Part[] memory parts = getPartsForSeed(seed);
        bytes memory headImage = getHeadImage(_tokenId);
        parts[2] = ISVGRenderer.Part({image: headImage, palette: descriptor.palettes(uint8(0))});

        uint256 randomBackground = uint256(getTokenRandomness(_tokenId)) % 2;
        string memory background = descriptor.backgrounds(randomBackground);

        NFTDescriptorV2.TokenURIParams memory params = NFTDescriptorV2.TokenURIParams({
            name: "My token that i will name later",
            description: "test token",
            parts: parts,
            background: background
        });
        return NFTDescriptorV2.constructTokenURI(descriptor.renderer(), params);
    }

    function createColors(bytes32 randomNum) public pure returns (uint8[3] memory) {
        uint8 a;
        uint8 b;
        uint8 c;
        (randomNum, a) = getColor(randomNum);
        (randomNum, b) = getColor(randomNum);
        // naively avoid same colors
        if (a == b) {
            (randomNum, b) = getColor(randomNum);
        }
        (randomNum, c) = getColor(randomNum);
        // naively avoid same colors
        if (a == c || b == c) {
            (randomNum, c) = getColor(randomNum);
        }
        return [a, b, c];
    }

    function getColor(bytes32 randomNum) internal pure returns (bytes32, uint8) {
        randomNum = moreRandom(randomNum);
        // palette length is 239 colors
        return (randomNum, uint8(uint256(randomNum) % 238) + 1); // avoid clear
    }

    function createImageData(bytes32 randomNum) internal pure returns (uint8[256] memory) {
        uint8[256] memory data;
        for (uint8 y = 0; y < 16; y++) {
            uint8[8] memory row;
            for (uint8 x = 0; x < 8; x++) {
                // this makes foreground and background color to have a 43% (1/2.3) probability
                // spot color has 13% chance
                randomNum = moreRandom(randomNum);
                uint8 value = uint8(uint256(randomNum) % 100 * 23 / 1000);
                row[x] = value;
                data[y * 16 + x] = value;
            }
            uint8[8] memory r = reverseArray(row);
            for (uint8 i; i < 8; i++) {
                data[y * 16 + i + 8] = r[i];
            }
        }

        return data;
    }

    function reverseArray(uint8[8] memory _array) public pure returns (uint8[8] memory) {
        uint8[8] memory reversedArray;
        uint256 j = 0;
        for (uint8 i = 8; i >= 1; i--) {
            reversedArray[j] = _array[i - 1];
            j++;
        }
        return reversedArray;
    }

    function getSeed(uint256 tokenId) internal view returns (INounsSeeder.Seed memory) {
        // uint256 tokenId = _tokenIdCounter.current() + 1;
        return seeder.generateSeed(tokenId, descriptor);
    }

    function getPartsForSeed(INounsSeeder.Seed memory seed) internal view returns (ISVGRenderer.Part[] memory) {
        return descriptor.getPartsForSeed(seed);
    }

    function getBackground(INounsSeeder.Seed memory seed) internal view returns (string memory) {
        return descriptor.backgrounds(seed.background);
    }

    function getTokenRandomness(uint256 _tokenId) public view returns (bytes32) {
        address addressToRender = this.ownerOf(_tokenId);
        return keccak256(abi.encodePacked(addressToRender));
    }

    function moreRandom(bytes32 randomNum) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(randomNum));
    }
}
