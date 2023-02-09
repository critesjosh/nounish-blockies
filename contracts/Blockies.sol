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

    function safeMint() payable public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        recipient.transfer(msg.value);
    }

    function tokenURI(uint256 _tokenId) public view
        override
        returns (string memory)
    {
        bytes memory addressToRender = toAsciiBytes(this.ownerOf(_tokenId));
        uint256 size = 8;
        uint256 scale = 2;

        int256[4] memory randseed;
        for (uint256 i = 0; i < addressToRender.length; i++) {
            randseed[i % 4] = (randseed[i % 4] << 5) - randseed[i % 4] + int8(uint8(addressToRender[i]));
	    }
        string memory color;
        string memory bgcolor;
        string memory spotColor;
        (randseed, color) = createColor(randseed);
        (randseed, bgcolor) = createColor(randseed);
        (randseed, spotColor) = createColor(randseed);
        uint256[8] memory imageData = createImageData(randseed);

        string memory svgMarkup = "<svg width='16' height='16' viewBox='0 0 16 16' xmlns='http://www.w3.org/2000/svg'><rect width='16' height='16' fill='";
		svgMarkup = string.concat(svgMarkup, bgcolor, "'/><g fill='", color, "'>");
        for(uint256 i = 0; i < 8; i++){
            if(imageData[i] == 1){
                string memory row = Strings.toString((i % size) * scale);
                string memory col = Strings.toString((i / size) / 2 * scale);
                svgMarkup = string.concat(svgMarkup, "<rect width='2' height='2' x='", row, "' y='", col, "' />");
            }
        }
        svgMarkup = string.concat(svgMarkup, "</g><g fill='", spotColor, "'>");
        for(uint256 i = 0; i < 8; i++){
            if(imageData[i] == 2){
                string memory row = Strings.toString((i % size) * scale);
                string memory col = Strings.toString((i / size) / 2 * scale);
                svgMarkup = string.concat(svgMarkup, "<rect width='2' height='2' x='", row, "' y='", col, "' />");
            }
        }
        svgMarkup = string.concat(svgMarkup, "</g></svg>");
        return string.concat("data:image/svg+xml;base64,", Base64.encode(bytes(svgMarkup)));
    }

    function toAsciiBytes(address x) internal pure returns (bytes memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return s;
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function rand(int256[4] memory _randseed) public pure returns(int256[4] memory, uint256){
        // based on Java's String.hashCode(), expanded to 4 32bit values
        int256 t = _randseed[0] ^ (_randseed[0] << 11);

        _randseed[0] = _randseed[1];
        _randseed[1] = _randseed[2];
        _randseed[2] = _randseed[3];
        _randseed[3] = _randseed[3] ^ (_randseed[3] >> 19) ^ t ^ (t >> 8);

        return (_randseed, uint256(_randseed[3] >> 0) / uint256((1 << 31) >> 0));
    }

    function createColor(int256[4] memory _randseed) public pure returns (int256[4] memory, string memory) {
        //saturation is the whole color spectrum
        uint256 x;
        (_randseed, x) = rand(_randseed);
        string memory h = Strings.toString(uint(x * 360) / 2);
        uint256 y;
        (_randseed, y) = rand(_randseed);
        //saturation goes from 40 to 100, it avoids greyish colors
        string memory s = string.concat(Strings.toString(uint(y * 60 + 40) / 2), '%');

        uint256 a;
        uint256 b;
        uint256 c;
        uint256 d;
        (_randseed, a) = rand(_randseed);
        (_randseed, b) = rand(_randseed);
        (_randseed, c) = rand(_randseed);
        (_randseed, d) = rand(_randseed);
        //lightness can be anything from 0 to 100, but probabilities are a bell curve around 50%
        string memory l = string.concat(Strings.toString(uint(a+b+c+d) * 25 / 2), '%');
        return (_randseed, string.concat("hsl(", h, ",",s,",",l,")"));
    }

    function createImageData(int256[4] memory _randseed) internal pure returns (uint[8] memory) {
        uint[8] memory data;
        for (uint8 y = 0; y < 4; y++) {
            uint256[4] memory row;
            for (uint8 x = 0; x < 4; x++) {
                // this makes foreground and background color to have a 43% (1/2.3) probability
                // spot color has 13% chance
                uint256 a;
                (_randseed, a) = rand(_randseed);
                uint value = uint256(a * 23 / 10) / 2;
                row[x] = value;
                data[x] = value;
            }
            uint[4] memory r = reverseArray(row);
            for(uint i; i < 4; i++) {
                data[i+4] = r[i];
            }
        }

        return data;
    }    

    function reverseArray(uint[4] memory _array) public pure returns(uint[4] memory) {
        uint[4] memory reversedArray;
        uint j = 0;
        for(uint i = 4; i >= 1; i--) {
            reversedArray[j] = _array[i-1];
            j++;
        }
        return reversedArray;
    }

}
