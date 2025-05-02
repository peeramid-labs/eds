// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../middleware/LibMiddleware.sol";
import "../interfaces/IERC7746.sol";

/**
 * @title LibMiddlewareExtendedTest
 * @dev Contract to directly test LibMiddleware library functions
 */
contract LibMiddlewareExtendedTest {
    // Direct call to accessLayersStorage
    function testAccessLayersStorage() external {
        LibMiddleware.LayerStruct[] storage layers = LibMiddleware.accessLayersStorage();
        // Just to access it, we don't need to do anything with it
    }

    // Test setLayer function
    function testSetLayer(address layerAddress, uint256 layerIndex, bytes memory layerConfigData) external {
        LibMiddleware.setLayer(layerAddress, layerIndex, layerConfigData);
    }

    // Test addLayer function (with struct)
    function testAddLayer(address layerAddress, bytes memory layerConfigData) external {
        LibMiddleware.LayerStruct memory layer = LibMiddleware.LayerStruct({
            layerAddress: layerAddress,
            layerConfigData: layerConfigData
        });
        LibMiddleware.addLayer(layer);
    }

    // Test addLayer function (with params)
    function testAddLayerWithParams(address layerAddress, bytes memory layerConfigData) external {
        LibMiddleware.addLayer(layerAddress, layerConfigData);
    }

    // Test changeLayers function
    function testChangeLayers(LibMiddleware.LayerStruct[] memory newLayers) external {
        LibMiddleware.changeLayers(newLayers);
    }

    // Test setLayers function
    function testSetLayers(LibMiddleware.LayerStruct[] memory newLayers) external {
        LibMiddleware.setLayers(newLayers);
    }

    // Test popLayer function
    function testPopLayer() external {
        LibMiddleware.popLayer();
    }

    // Test getLayer function
    function testGetLayer(uint256 layerIdx) external view returns (address, bytes memory) {
        LibMiddleware.LayerStruct storage layer = LibMiddleware.getLayer(layerIdx);
        return (layer.layerAddress, layer.layerConfigData);
    }

    // Test beforeCall function
    function testBeforeCall(
        bytes4 selector,
        address sender,
        bytes calldata data,
        uint256 value
    ) external returns (bytes[] memory) {
        return LibMiddleware.beforeCall(selector, sender, data, value);
    }

    // Test validateLayerBeforeCall function
    function testValidateLayerBeforeCall(
        uint256 layerIdx,
        bytes4 selector,
        address sender,
        bytes memory data,
        uint256 value
    ) external returns (bytes memory) {
        LibMiddleware.LayerStruct storage layer = LibMiddleware.getLayer(layerIdx);
        return LibMiddleware.validateLayerBeforeCall(layer, selector, sender, data, value);
    }

    // Test afterCall function
    function testAfterCall(
        bytes4 selector,
        address sender,
        bytes calldata data,
        uint256 value,
        bytes[] memory beforeCallReturns
    ) external {
        LibMiddleware.afterCall(selector, sender, data, value, beforeCallReturns);
    }

    // Test validateLayerAfterCall function
    function testValidateLayerAfterCall(
        uint256 layerIdx,
        bytes4 selector,
        address sender,
        bytes calldata data,
        uint256 value,
        bytes memory beforeCallReturnValue
    ) external {
        LibMiddleware.LayerStruct storage layer = LibMiddleware.getLayer(layerIdx);
        LibMiddleware.validateLayerAfterCall(layer, selector, sender, data, value, beforeCallReturnValue);
    }

    // Test extractRevertReason function
    function testExtractRevertReason(bytes memory revertData) external pure returns (string memory) {
        return LibMiddleware.extractRevertReason(revertData);
    }

    // Get layer count function for testing
    function getLayerCount() external view returns (uint256) {
        return LibMiddleware.accessLayersStorage().length;
    }

    // Get layer at index function for testing
    function getLayerAt(uint256 index) external view returns (address layerAddress, bytes memory layerConfigData) {
        LibMiddleware.LayerStruct storage layer = LibMiddleware.accessLayersStorage()[index];
        return (layer.layerAddress, layer.layerConfigData);
    }
}