// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

abstract contract VyperTest is Test {

    function compileVyper(
        string memory fileLocation
    ) public returns (bytes memory byteCode) {
        string[] memory cmds = new string[](2);
        cmds[0] = "vyper";
        cmds[1] = fileLocation;
        return vm.ffi(cmds);
    }

    function compileVyper(
        string memory fileLocation, 
        bytes memory args
    ) public returns (bytes memory byteCodeWithArgs) {
        string[] memory cmds = new string[](2);
        cmds[0] = "vyper";
        cmds[1] = fileLocation;
        return abi.encodePacked(vm.ffi(cmds), args);
    }

    function deployByteCode(
        bytes memory vyperByteCode
    ) public returns (address contractAddr) {
        assembly {
            contractAddr := create(0, add(vyperByteCode, 0x20), mload(vyperByteCode))
        }
        require(
            contractAddr != address(0) && contractAddr.code.length > 0,
            "Vyper contract deployment failed"
        );
    }

    function deployContract(
        string memory fileLocation
    ) public returns (address contractAddr) {
        return deployByteCode(compileVyper(fileLocation));
    }

    function deployContract(
        string memory fileLocation, 
        bytes memory args
    ) public returns (address contractAddr) {
        return deployByteCode(compileVyper(fileLocation, args));
    }
}