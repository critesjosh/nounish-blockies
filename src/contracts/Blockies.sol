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
import {NFTDescriptorV2} from './libs/NFTDescriptorV2.sol';

contract Blockies is ERC721 {
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
        _safeMint(msg.sender, tokenId);
    }

    // Palette Index, Bounds [Top (Y), Right (X), Bottom (Y), Left (X)] (4 Bytes), 
    // [Pixel Length (1 Byte), Color Index (1 Byte)][]
    function getHeadImage(uint tokenId) public returns (bytes memory){
        // if(owner == address(0)){
        //     error NoOwner();
        // }
        uint256[144] memory imagedata = createImageData(getTokenRandomness(tokenId));

        bytes memory headImage;

        bytes1 palatte = 0x00;
        bytes1 top = 0x05;
        bytes1 right = 0x17;
        bytes1 bottom = 0x14;
        bytes1 left = 0x08;

        headImage.push(palatte);
        headImage.push(top);
        headImage.push(right);
        headImage.push(bottom);
        headImage.push(left);

        // uint256 palleteLength = 1431;
        uint256[3] memory colors = createColors(getTokenRandomness(tokenId), 16);

        for (uint256 i = 0; i < 144; i++) {
            headImage.push(0x01);
            headImage.push(colors[imagedata[i]]);
        }
        return headImage;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        INounsSeeder.Seed memory seed = getSeed(_tokenId);
        ISVGRenderer.Part[] memory parts = getPartsForSeed(seed);
        bytes memory headImage = getHeadImage(_tokenId);
        parts[2] = ISVGRenderer.Part({ image: headImage, palette: _getPalette(headImage) });
        
        uint8 randomBackground = uint8(getTokenRandomness(_tokenId)) % 2;
        string memory background = descriptor.backgrounds();
        
        NFTDescriptorV2.TokenURIParams memory params = NFTDescriptorV2.TokenURIParams({
            name: "My token that i will name later",
            description: "test token",
            parts: getPartsForSeed(seed),
            background: background
        });
        return NFTDescriptorV2.constructTokenURI(descriptor.renderer(), params);
    }

    function createColors(bytes32 randomNum, uint256 maxValue) public pure returns (uint256[3] memory) {
        uint a;
        uint b;
        uint c;
        randomNum = moreRandom(randomNum);
        a = randomNum % maxValue;
        randomNum = moreRandom(randomNum);
        b = randomNum % maxValue;
        randomNum = moreRandom(randomNum);
        c = randomNum % maxValue;
        return [a,b,c];
    }

    function createImageData(bytes32 randomNum) internal pure returns (uint256[144] memory) {
        uint256[144] memory data;
        for (uint8 y = 0; y < 12; y++) {
            uint256[6] memory row;
            for (uint8 x = 0; x < 6; x++) {
                // this makes foreground and background color to have a 43% (1/2.3) probability
                // spot color has 13% chance
                randomNum = moreRandom(randomNum);
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
    
    function getSeed(uint256 tokenId) internal view returns (INounsSeeder.Seed memory) {
        // uint256 tokenId = _tokenIdCounter.current() + 1;
        return seeder.generateSeed(tokenId, address(descriptor));
    }

    function getPartsForSeed(INounsSeeder.Seed memory seed) internal view returns (ISVGRenderer.Part[] memory) {
        return descriptor.getPartsForSeed(seed);
    }

    function getBackground(INounsSeeder.Seed memory seed) internal view returns (string memory){
        return descriptor.backgrounds(seed.background);
    }
    
    function getTokenRandomness(uint256 _tokenId) public returns (bytes32) {
        address addressToRender = this.ownerOf(_tokenId);
        bytes32 randomNum = keccak256(abi.encodePacked(addressToRender));
    }

    function moreRandom(bytes32 randomNum) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(randomNum));
    }

    function _getPalette(bytes memory part) internal returns (bytes memory) {
        return descriptor.palettes(uint8(part[0]));
    }

}
