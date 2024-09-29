// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "./ERC7746Middleware.sol";
import "../libraries/LibMiddleware.sol";

/**
 * @dev This contract is a modified OpenZeppelin proxy v5.0.0.
 * Modification wraps a fallback function within ERC7746.
 * Rest is similar to OpenZeppelin Proxy.sol
 */
contract MiddlewareProxy is ERC7746Middleware {
    address private immutable implementationAddress;

    constructor(LibMiddleware.LayerStruct[] memory layers, address implementation) {
        implementationAddress = implementation;
        LibMiddleware.setLayers(layers);
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback
     * function and {_fallback} should delegate.
     */
    function _implementation() internal view returns (address) {
        return implementationAddress;
    }

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        (bool success, bytes memory result) = _implementation().delegatecall(msg.data);
        if (!success) {
            // If the call failed, bubble up the revert reason if present
            if (result.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                assembly {
                    let returndata_size := mload(result)
                    revert(add(32, result), returndata_size)
                }
            } else {
                revert("delegatecall failed without revert reason");
            }
        }
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual ERC7746 {
        _fallback();
    }
}
