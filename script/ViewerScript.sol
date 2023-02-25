// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {NounishBlockies} from "../src/contracts/NounishBlockies.sol";
import {INounsSeeder} from "../src/contracts/interfaces/INounsSeeder.sol";
import {INounsDescriptorV2} from "../src/contracts/interfaces/INounsDescriptorV2.sol";

contract ViewerScript is Script {
    address seederAddress = 0xCC8a0FB5ab3C7132c1b2A0109142Fb112c4Ce515;
    address descriptorAddress = 0x6229c811D04501523C6058bfAAc29c91bb586268;

    address[10] accounts = [
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
        0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,
        0x90F79bf6EB2c4f870365E785982E1f101E93b906,
        0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65,
        0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc,
        0x976EA74026E726554dB657fA54763abd0C3a0aa9,
        0x14dC79964da2C08b23698B3D3cc7Ca32193d9955,
        0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f,
        0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
    ];

    event log_string(string);

    function setUp() public {}

    function run() public {
        vm.broadcast();
        NounishBlockies blockiesContract = new NounishBlockies(seederAddress, descriptorAddress);

        for (uint256 i = 0; i < 8; i++) {
            vm.prank(accounts[i % 10]);
            INounsSeeder seederContract = INounsSeeder(blockiesContract.seeder());
            INounsDescriptorV2 descriptorContract = INounsDescriptorV2(blockiesContract.descriptor());
            INounsSeeder.Seed memory seed = seederContract.generateSeed(i, descriptorContract);
            string memory headstring = blockiesContract.renderNounishBlockie(0x9ae3b3C41b0466717fD53d4E2612611Ee8Ec9a84, seed);
            emit log_string(headstring);

            // blockiesContract.safeMint();
            // string memory endcodednft = blockiesContract.tokenURI(i);
        }


            string memory head = blockiesContract.getHeadSvg(0x25219Db063Ab2124c011D63f860Bff6FfE1ac725);
            emit log_string(head);
        // emit log_string(endcodednft);
    }
}
