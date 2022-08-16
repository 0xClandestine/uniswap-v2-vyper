// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.13;

// import "../test/utils/VyperTest.sol";

// library Math {
//     // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
//     function sqrt(uint y) internal pure returns (uint z) {
//         unchecked{
//             if (y > 3) {
//                 z = y;
//                 uint x = y / 2 + 1;
//                 while (x < z) {
//                     z = x;
//                     x = (y / x + x) / 2;
//                 }
//             } else if (y != 0) {
//                 z = 1;
//             }
//         }
//     }
// }

// interface IMath {
//     function sqrt256(uint y) external returns (uint z) ;
// }

// contract MathTest is VyperTest {
//     function test_sqrt256(uint y) public {

//         vm.assume(y > 0);
//         vm.assume(y < type(uint).max);

//         IMath math = IMath(VyperTest.deployContract("src/test/mocks/Math.vy"));

//         assertEq(math.sqrt256(y), Math.sqrt(y));
//     }
// }