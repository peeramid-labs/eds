// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../middleware/ERC7746Hooked.sol";
import "../middleware/LibMiddleware.sol";

/**
 * @title MockERC7746HookedTest
 * @dev Special contract to help test ERC7746Hooked modifiers
 */
contract MockERC7746HookedTest is ERC7746Hooked {
    event FunctionCalled(bytes4 selector, address sender, bytes data, uint256 value);
    event BeforeCallExecuted(bytes[] layerReturns);
    event AfterCallExecuted();

    string public testValue;
    bool public functionExecuted;

    // This will set up the middleware layers directly
    function setupMiddlewareLayers(address[] memory middlewareAddresses, bytes[] memory configData) external {
        require(middlewareAddresses.length == configData.length, "Input arrays must have the same length");

        // Clear existing layers
        LibMiddleware.LayerStruct[] storage layers = LibMiddleware.accessLayersStorage();
        uint256 length = layers.length;
        for (uint256 i = 0; i < length; i++) {
            LibMiddleware.popLayer();
        }

        // Add new layers
        for (uint256 i = 0; i < middlewareAddresses.length; i++) {
            LibMiddleware.addLayer(middlewareAddresses[i], configData[i]);
        }
    }

    // Test modifiers and emit events to track execution
    function testERC7746CModifier(
        bytes4 _selector,
        address _sender,
        bytes calldata _data,
        uint256 _value,
        string calldata newValue
    ) external ERC7746C(_selector, _sender, _data, _value) returns (bool) {
        testValue = newValue;
        functionExecuted = true;
        emit FunctionCalled(_selector, _sender, _data, _value);
        return true;
    }

    function testERC7746Modifier(string calldata newValue) external payable ERC7746 returns (bool) {
        testValue = newValue;
        functionExecuted = true;
        return true;
    }

    function setValueNoMiddleware(string calldata newValue) external returns (bool) {
        testValue = newValue;
        functionExecuted = true;
        return true;
    }

    // Override the ERC7746C modifier to emit events for testing
    modifier ERC7746C_Tracked(bytes4 _selector, address sender, bytes calldata data, uint256 value) {
        bytes[] memory layerReturns = LibMiddleware.beforeCall(_selector, sender, data, value);
        emit BeforeCallExecuted(layerReturns);
        _;
        LibMiddleware.afterCall(_selector, sender, data, value, layerReturns);
        emit AfterCallExecuted();
    }

    // Function that uses the tracked modifier for enhanced testing
    function testTrackedModifier(
        bytes4 _selector,
        address _sender,
        bytes calldata _data,
        uint256 _value,
        string calldata newValue
    ) external ERC7746C_Tracked(_selector, _sender, _data, _value) returns (bool) {
        testValue = newValue;
        functionExecuted = true;
        emit FunctionCalled(_selector, _sender, _data, _value);
        return true;
    }

    // Helper functions to access the storage directly
    function getLayerCount() external view returns (uint256) {
        return LibMiddleware.accessLayersStorage().length;
    }

    function getLayerAt(uint256 index) external view returns (address middleware, bytes memory configData) {
        LibMiddleware.LayerStruct storage layer = LibMiddleware.accessLayersStorage()[index];
        return (layer.layerAddress, layer.layerConfigData);
    }
}
