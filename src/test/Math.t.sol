// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../../lib/ds-test/test.sol";
import "../../lib/utils/Console.sol";
import "../../lib/utils/VyperDeployer.sol";
import "./utils/Console.sol";
import "./utils/VM.sol";

library Math {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        unchecked{
            if (y > 3) {
                z = y;
                uint x = y / 2 + 1;
                while (x < z) {
                    z = x;
                    x = (y / x + x) / 2;
                }
            } else if (y != 0) {
                z = 1;
            }
        }
    }
}

interface IMath {
    function sqrt256(uint y) external returns (uint z) ;
}

contract MathTest is DSTest {
    ///@notice create a new instance of VyperDeployer
    VyperDeployer vyperDeployer = new VyperDeployer();

    VM vm = VM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    IMath math;

    function setUp() public {
        math = IMath(vyperDeployer.deployContract("Math"));
    }

    function test_sqrt256(uint y) public {

        if (y > 0 && y < type(uint256).max) {
            uint256 output = math.sqrt256(y);

            require(output == Math.sqrt(y));
        }
    }
}