// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.13;

// import "../test/utils/VyperTest.sol";

// library UQ112x112 {
//     uint224 constant Q112 = 2**112;

//     // encode a uint112 as a UQ112x112
//     function encode(uint112 y) internal pure returns (uint224 z) {
//         z = uint224(y) * Q112; // never overflows
//     }

//     // divide a UQ112x112 by a uint112, returning a UQ112x112
//     function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
//         z = x / uint224(y);
//     }
// }

// interface IUQ112x112 {
//     function encode(uint112 y) external returns (uint224 z);
//     function uqdiv(uint224 x, uint112 y) external returns (uint256 z);
// }

// contract UQ112x112Test is VyperTest {

//     IUQ112x112 math;

//     function setUp() public {
//         math = IUQ112x112(deployContract("src/test/mocks/UQ112x112.vy"));
//     }

//     function test_encode(uint112 y) public {
//         uint224 output = math.encode(y);

//         require(output == UQ112x112.encode(y));
//     }

//     function test_uqdiv(uint224 x, uint112 y) public {
//         if (x > 0 && y > 0) {
//             uint256 output = math.uqdiv(x, y);

//             require(output == uint256(UQ112x112.uqdiv(x, y)));
//         }
//     }
// }