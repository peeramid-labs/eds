// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title MockERC165WithFunctions
 * @dev A mock contract for testing that allows setting which interfaces are supported
 * and also simulating function calls with preset return values
 */
contract MockERC165WithFunctions is ERC165 {
    mapping(bytes4 => bool) private _supportedInterfaces;
    mapping(string => bytes) private _functionResults;

    // ERC165 interface ID
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    constructor() {
        // ERC165 is always supported
        _supportedInterfaces[_INTERFACE_ID_ERC165] = true;
    }

    /**
     * @dev Sets whether a specific interface is supported
     * @param interfaceId Interface ID to check support for
     * @param supported Whether the interface should be reported as supported
     */
    function setSupportedInterface(bytes4 interfaceId, bool supported) external {
        require(interfaceId != _INTERFACE_ID_ERC165, "ERC165: cannot set ERC165 interface support");
        _supportedInterfaces[interfaceId] = supported;
    }

    /**
     * @dev Sets the result of a function call
     * @param functionSignature The function signature (e.g., "beforeCall(bytes,bytes4,address,uint256,bytes)")
     * @param result The bytes result to return when the function is called
     */
    function setFunctionResult(string memory functionSignature, bytes memory result) external {
        _functionResults[functionSignature] = result;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId] || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Fallback function to handle all other calls and return preset results.
     * This allows mocking any interface function.
     */
    fallback() external {
        bytes4 selector = msg.sig;

        // Convert selector to string representation for lookup
        string memory funcSig = _getSelectorString(selector);

        // If we have a preset result for this function, return it
        if (_hasResult(funcSig)) {
            bytes memory result = _functionResults[funcSig];
            assembly {
                return(add(result, 0x20), mload(result))
            }
        }

        // Otherwise return empty bytes
        bytes memory empty = new bytes(0);
        assembly {
            return(add(empty, 0x20), mload(empty))
        }
    }

    /**
     * @dev Check if we have a preset result for this function
     */
    function _hasResult(string memory funcSig) internal view returns (bool) {
        return _functionResults[funcSig].length > 0;
    }

    /**
     * @dev Helper function to get a stringified function selector
     * For actual usage, you would need to register the signatures manually
     * since getting the full signature from the selector is not possible
     */
    function _getSelectorString(bytes4 selector) internal pure returns (string memory) {
        // For test purposes, this function would return a hardcoded value
        // for known selectors or a default representation for unknown ones

        // This is a simplification - in practice, you'd match known selectors
        // or use the string literal signature from the start
        bytes memory b = new bytes(10);
        assembly {
            mstore(add(b, 32), selector)
        }

        // Return empty string as fallback
        return string(b);
    }

    // Explicitly declare function signatures for the middleware functions

    function beforeCall(bytes memory, bytes4, address, uint256, bytes memory) external returns (bytes memory) {
        string memory funcSig = "beforeCall(bytes,bytes4,address,uint256,bytes)";
        if (_hasResult(funcSig)) {
            return _functionResults[funcSig];
        }
        return new bytes(0);
    }

    function afterCall(bytes memory, bytes4, address, uint256, bytes memory, bytes memory) external {
        // No return value needed
    }
}
