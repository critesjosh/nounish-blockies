import {NounishBlockies} from "../src/contracts/NounishBlockies.sol";

contract NounishBlockiesTest {

    function testMint() public {
        NounishBlockies blockiesContract = new NounishBlockies(0xCC8a0FB5ab3C7132c1b2A0109142Fb112c4Ce515, 0x6229c811D04501523C6058bfAAc29c91bb586268);
        blockiesContract.mint(msg.sender);
    }

}