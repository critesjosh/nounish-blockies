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

contract Blockies is ERC721 {
    using Counters for Counters.Counter;

    NounsDescriptorV2 public descriptor;

    Counters.Counter private _tokenIdCounter;

    error NoOwner();

    constructor(address _descriptor) ERC721("Blockies", "BLKS") {
        descriptor = NounsDescriptorV2(_descriptor);
    }

    function safeMint() public payable {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId);
        // _safeMint(msg.sender, tokenId);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
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
        uint8[] memory data;
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

    function getTokenRandomness(uint256 _tokenId) public view returns (bytes32) {
        address addressToRender = this.ownerOf(_tokenId);
        return keccak256(abi.encodePacked(addressToRender));
    }

    function moreRandom(bytes32 randomNum) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(randomNum));
    }
}
