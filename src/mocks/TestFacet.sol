// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract TestFacet {
    event Bar();

    function foo() public {
        emit Bar();
    }

    function ping() public pure returns (string memory) {
        return "pong";
    }
}
