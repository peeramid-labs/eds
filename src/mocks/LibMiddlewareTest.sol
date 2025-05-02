// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../middleware/LibMiddleware.sol";
import "../interfaces/IERC7746.sol";

contract LibMiddlewareTest {
    // Define the MiddlewareConfig struct that mirrors what LibMiddleware uses internally
    struct MiddlewareConfig {
        address middleware;
        bytes configData;
    }

    function createKey(address target, bytes4 selector) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(target, selector));
    }

    function encodeConfig(address middleware, bytes memory configData) public pure returns (bytes memory) {
        MiddlewareConfig memory config = MiddlewareConfig({
            middleware: middleware,
            configData: configData
        });
        return abi.encode(config);
    }

    function getConfig(bytes memory encodedConfig) public pure returns (MiddlewareConfig memory) {
        return abi.decode(encodedConfig, (MiddlewareConfig));
    }

    function getLayerTest(bytes[] memory middlewareLayers, uint256 index) public pure returns (MiddlewareConfig memory) {
        return getConfig(middlewareLayers[index]);
    }

    function executeBeforeCall(
        bytes[] memory middlewareLayers,
        bytes4 selector,
        address sender,
        uint256 value,
        bytes memory data
    ) public returns (bytes memory) {
        bytes memory lastResult;
        for (uint256 i = 0; i < middlewareLayers.length; i++) {
            MiddlewareConfig memory config = getConfig(middlewareLayers[i]);
            lastResult = IERC7746(config.middleware).beforeCall(
                config.configData,
                selector,
                sender,
                value,
                data
            );
        }
        return lastResult;
    }

    function executeAfterCall(
        bytes[] memory middlewareLayers,
        bytes4 selector,
        address sender,
        uint256 value,
        bytes memory data,
        bytes memory beforeCallResult
    ) public {
        for (uint256 i = middlewareLayers.length; i > 0; i--) {
            MiddlewareConfig memory config = getConfig(middlewareLayers[i-1]);
            IERC7746(config.middleware).afterCall(
                config.configData,
                selector,
                sender,
                value,
                data,
                beforeCallResult
            );
        }
    }
}