// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC7746.sol";

contract MockMiddlewareTarget {
    address public middleware;

    constructor(address _middleware) {
        middleware = _middleware;
    }

    function simulateBeforeCall(
        address hook,
        bytes4 selector,
        address sender,
        uint256 value,
        bytes memory data
    ) external returns (bytes memory) {
        return IERC7746(hook).beforeCall("0x", selector, sender, value, data);
    }

    function simulateAfterCall(
        address hook,
        bytes4 selector,
        address sender,
        uint256 value,
        bytes memory data,
        bytes memory beforeCallResult
    ) external {
        IERC7746(hook).afterCall("0x", selector, sender, value, data, beforeCallResult);
    }
}