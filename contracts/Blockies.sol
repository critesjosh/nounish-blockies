// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract Blockies is ERC721 {
    using Counters for Counters.Counter;

    address payable recipient = payable(0x7D678b9218aC289e0C9F18c82F546c988BfE3022);

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Blockies", "BLKS") {}

    function safeMint() public payable {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        recipient.transfer(msg.value);
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
        uint256[256] memory imageData = createImageData(randomNum);

        uint size = 16;
        uint scale = 5;

        string memory svgMarkup =
            "<svg width='80' height='80' viewBox='0 0 80 80' xmlns='http://www.w3.org/2000/svg'><rect width='80' height='80' fill='";
        svgMarkup = string.concat(svgMarkup, bgcolor, "'/><g fill='", color, "'>");
        for (uint256 i = 0; i < 256; i++) {
            if (imageData[i] == 1) {
                string memory row = Strings.toString((i % size) * scale);
                string memory col = Strings.toString((i / size) * scale);
                svgMarkup = string.concat(svgMarkup, "<rect width='", Strings.toString(scale), "' height='", Strings.toString(scale),"' x='", row, "' y='", col, "' />");
            }
        }
        svgMarkup = string.concat(svgMarkup, "</g><g fill='", spotColor, "'>");
        for (uint256 i = 0; i < 256; i++) {
            if (imageData[i] == 2) {
                string memory row = Strings.toString((i % size) * scale);
                string memory col = Strings.toString((i / size) * scale);
                svgMarkup = string.concat(svgMarkup, "<rect width='", Strings.toString(scale), "' height='", Strings.toString(scale),"' x='", row, "' y='", col, "' />");
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

    function createImageData(bytes32 randomNum) internal pure returns (uint256[256] memory) {
        uint256[256] memory data;
        for (uint8 y = 0; y < 16; y++) {
            uint256[8] memory row;
            for (uint8 x = 0; x < 8; x++) {
                // this makes foreground and background color to have a 43% (1/2.3) probability
                // spot color has 13% chance
                randomNum = rand(randomNum);
                uint256 value = uint256(randomNum) % 100 * 23 / 1000;
                row[x] = value;
                data[y*16 + x] = value;
            }
            uint256[8] memory r = reverseArray(row);
            for (uint256 i; i < 8; i++) {
                data[y*16 + i + 8] = r[i];
            }
        }

        return data;
    }

    function reverseArray(uint256[8] memory _array) public pure returns (uint256[8] memory) {
        uint256[8] memory reversedArray;
        uint256 j = 0;
        for (uint256 i = 8; i >= 1; i--) {
            reversedArray[j] = _array[i - 1];
            j++;
        }
        return reversedArray;
    }
}
