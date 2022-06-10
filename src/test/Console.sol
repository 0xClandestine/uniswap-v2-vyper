// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "../../node_modules/@openzeppelin/contracts/utils/Strings.sol";

library Console {
    function log(
        string memory _condition,
        uint256 _return
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(_condition, " returned: ", Strings.toString(_return)));
    }
}