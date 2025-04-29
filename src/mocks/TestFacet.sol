// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract TestFacet {
    event Bar();
    event Initialized();

    function initialize() public {
        emit Initialized();
    }

    function foo() public {
        emit Bar();
    }

    function ping() public pure returns (string memory) {
        return "pong";
    }
}
