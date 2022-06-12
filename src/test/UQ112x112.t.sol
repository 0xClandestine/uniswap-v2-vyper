// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../../lib/ds-test/test.sol";
import "../../lib/utils/Console.sol";
import "../../lib/utils/VyperDeployer.sol";
import "./utils/Console.sol";
import "./utils/VM.sol";

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

interface IUQ112x112 {

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) external returns (uint224 z);

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) external returns (uint256 z);
}

contract UQ112x112Test is DSTest {
    ///@notice create a new instance of VyperDeployer
    VyperDeployer vyperDeployer = new VyperDeployer();

    VM vm = VM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    IUQ112x112 math;

    function setUp() public {
        math = IUQ112x112(vyperDeployer.deployContract("UQ112x112"));
    }

    function test_encode(uint112 y) public {
        uint224 output = math.encode(y);

        require(output == UQ112x112.encode(y));
    }

    function test_uqdiv(uint224 x, uint112 y) public {
        if (x > 0 && y > 0) {
            uint256 output = math.uqdiv(x, y);

            require(output == uint256(UQ112x112.uqdiv(x, y)));
        }
    }
}