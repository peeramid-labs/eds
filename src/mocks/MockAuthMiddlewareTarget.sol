// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC7746.sol";

/**
 * Simple mock target for testing AuthorizationMiddleware
 */
contract MockAuthMiddlewareTarget {
    address public middleware;

    constructor(address _middleware) {
        middleware = _middleware;
    }

    function simulateBeforeCall(
        bytes4 selector,
        address sender,
        uint256 value,
        bytes memory data
    ) external returns (bytes memory) {
        return IERC7746(middleware).beforeCall("0x", selector, sender, value, data);
    }

    function simulateAfterCall(
        bytes4 selector,
        address sender,
        uint256 value,
        bytes memory data,
        bytes memory beforeCallResult
    ) external {
        IERC7746(middleware).afterCall("0x", selector, sender, value, data, beforeCallResult);
    }

    // These methods are for testing disallowed addresses and distribution-only flags

    // Method for testing distribution-only when allowed
    function testDistributionOnly(address sender) external returns (bytes memory) {
        bytes4 selector = this.testDistributionOnly.selector;
        return IERC7746(middleware).beforeCall("0x", selector, sender, 0, "0x");
    }

    // Method for testing non-distribution-only
    function testNonDistributionOnly(address sender) external returns (bytes memory) {
        bytes4 selector = this.testNonDistributionOnly.selector;
        return IERC7746(middleware).beforeCall("0x", selector, sender, 0, "0x");
    }

    // Method for testing afterCall with distribution-only
    function testAfterCallDistributionOnly(address sender) external {
        bytes4 selector = this.testAfterCallDistributionOnly.selector;
        IERC7746(middleware).afterCall("0x", selector, sender, 0, "0x", "0x");
    }
}