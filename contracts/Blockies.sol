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

contract Blockies is ERC721 {
    using Counters for Counters.Counter;

    INounsSeeder public seeder;
    NounsDescriptorV2 public descriptor;

    Counters.Counter private _tokenIdCounter;

    constructor(address _seeder, address _descriptor) ERC721("Blockies", "BLKS") {
        seeder = INounsSeeder(_seeder);
        descriptor = INounsDescriptorV2(_descriptor);
    }

    function safeMint() public payable {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function getSeed() internal view returns (INounsSeeder.Seed memory) {
        uint256 tokenId = _tokenIdCounter.current() + 1;
        return seeder.generateSeed(tokenId, address(descriptor));
    }

    function getPartsForSeed(INounsSeeder.Seed memory seed) internal view returns (ISVGRenderer.Part[] memory) {
        return descriptor.getPartsForSeed(seed);
    }

    function getBackground(INounsSeeder.Seed memory seed) internal view returns (string memory){
        return descriptor.backgrounds(seed.background);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        address addressToRender = this.ownerOf(_tokenId);

        bytes32 randomNum = keccak256(abi.encodePacked(addressToRender));

        string memory color;
        string memory bgcolor;
        string memory spotColor;
        (randomNum, color) = createColor(randomNum);
        (randomNum, bgcolor) = createColor(randomNum);
        (randomNum, spotColor) = createColor(randomNum);
        uint256[144] memory imageData = createImageData(randomNum);

        uint256 size = 12;
        uint256 scale = 10;

        string memory svgMarkup = string.concat(
            "<svg width='",
            Strings.toString(size * scale),
            "' height='",
            Strings.toString(size * scale),
            "' viewBox='0 0 ",
            Strings.toString(size * scale),
            " ",
            Strings.toString(size * scale),
            "' xmlns='http://www.w3.org/2000/svg'>"
        );
        svgMarkup = string.concat(
            svgMarkup,
            "<rect width='",
            Strings.toString(size * scale),
            "' height='",
            Strings.toString(size * scale),
            "' fill='"
        );
        svgMarkup = string.concat(svgMarkup, bgcolor, "'/><g fill='", color, "'>");
        for (uint256 i = 0; i < 144; i++) {
            if (imageData[i] == 1) {
                string memory row = Strings.toString((i % size) * scale);
                string memory col = Strings.toString((i / size) * scale);
                svgMarkup = string.concat(
                    svgMarkup,
                    "<rect width='",
                    Strings.toString(scale),
                    "' height='",
                    Strings.toString(scale),
                    "' x='",
                    row,
                    "' y='",
                    col,
                    "' />"
                );
            }
        }
        svgMarkup = string.concat(svgMarkup, "</g><g fill='", spotColor, "'>");
        for (uint256 i = 0; i < 144; i++) {
            if (imageData[i] == 2) {
                string memory row = Strings.toString((i % size) * scale);
                string memory col = Strings.toString((i / size) * scale);
                svgMarkup = string.concat(
                    svgMarkup,
                    "<rect width='",
                    Strings.toString(scale),
                    "' height='",
                    Strings.toString(scale),
                    "' x='",
                    row,
                    "' y='",
                    col,
                    "' />"
                );
            }
        }
        svgMarkup = string.concat(svgMarkup, "</g></svg>");
        return string.concat("data:image/svg+xml;base64,", Base64.encode(bytes(svgMarkup)));
    }

    function rand(bytes32 randomNum) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(randomNum));
    }

    function createColor(bytes32 randomNum) public pure returns (bytes32, string memory) {
        //saturation is the whole color spectrum
        randomNum = rand(randomNum);
        string memory h = Strings.toString((uint256(randomNum) % 100) * 36 / 10);
        randomNum = rand(randomNum);
        //saturation goes from 40 to 100, it avoids greyish colors
        string memory s = string.concat(Strings.toString(((uint256(randomNum) % 60) + 40)), "%");

        randomNum = rand(randomNum);
        uint256 a = uint256(randomNum) % 100;
        randomNum = rand(randomNum);
        uint256 b = uint256(randomNum) % 100;
        randomNum = rand(randomNum);
        uint256 c = uint256(randomNum) % 100;
        randomNum = rand(randomNum);
        uint256 d = uint256(randomNum) % 100;
        //lightness can be anything from 0 to 100, but probabilities are a bell curve around 50%
        string memory l = string.concat(Strings.toString((a + b + c + d) / 4), "%");
        return (randomNum, string.concat("hsl(", h, ",", s, ",", l, ")"));
    }

    function createImageData(bytes32 randomNum) internal pure returns (uint256[144] memory) {
        uint256[144] memory data;
        for (uint8 y = 0; y < 12; y++) {
            uint256[6] memory row;
            for (uint8 x = 0; x < 6; x++) {
                // this makes foreground and background color to have a 43% (1/2.3) probability
                // spot color has 13% chance
                randomNum = rand(randomNum);
                uint256 value = uint256(randomNum) % 100 * 23 / 1000;
                row[x] = value;
                data[y * 12 + x] = value;
            }
            uint256[6] memory r = reverseArray(row);
            for (uint256 i; i < 6; i++) {
                data[y * 12 + i + 6] = r[i];
            }
        }

        return data;
    }

    function reverseArray(uint256[6] memory _array) public pure returns (uint256[6] memory) {
        uint256[6] memory reversedArray;
        uint256 j = 0;
        for (uint256 i = 6; i >= 1; i--) {
            reversedArray[j] = _array[i - 1];
            j++;
        }
        return reversedArray;
    }
}
