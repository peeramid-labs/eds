// SPDX-License-Identifier: MIT

import "./ERC7746Middleware.sol";
import "../libraries/LibMiddleware.sol";
pragma solidity ^0.8.20;

/**
 * @dev This contract is a modified OpenZeppelin proxy v5.0.0.
 * Modification wraps a fallback function within ERC7746.
 * Rest is similar to OpenZeppelin Proxy.sol
 */
contract MiddlewareProxy is ERC7746Middleware {
    address immutable implementationAddress;

    constructor (LibMiddleware.LayerStruct[] memory layers, address implementation) {
        implementationAddress = implementation;
        LibMiddleware.setLayers(layers);
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback
     * function and {_fallback} should delegate.
     */
    function _implementation() internal view  returns (address)
    {
        return implementationAddress;
    }

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        (bool success, bytes memory result) = _implementation().delegatecall(msg.data);
        require(success, string(result));
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual ERC7746 {
        _fallback();
    }
}
