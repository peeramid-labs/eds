// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
import "./LibMiddleware.sol";

/**
 * @title ERC7746Middleware
 * @notice Abstract contract that serves as a middleware for ERC7746 standard.
 * This contract is intended to be inherited by other contracts that implement
 * the ERC7746 functionality. It provides base functionality and structure
 * that can be extended and customized by derived contracts.
 * @author Peeramid Labs, 2024
 */
abstract contract ERC7746Hooked {
    /**
     * @notice Modifier to apply custom logic for ERC7746 compliance.
     * @param _selector The function selector to be checked.
     * @param sender The address of the sender.
     * @param data The calldata being passed to the function.
     * @param value The value being transferred.
     */
    modifier ERC7746C(bytes4 _selector, address sender, bytes calldata data, uint256 value) {
        bytes[] memory layerReturns = LibMiddleware.beforeCall(_selector, sender, data, value);
        _;
        LibMiddleware.afterCall(_selector, sender, data, value, layerReturns);
    }

    /**
     * @notice Modifier to apply ERC7746 specific logic.
     * This modifier can be used to enforce certain conditions or
     * execute specific code before or after the function it modifies.
     */
    modifier ERC7746() {
        bytes[] memory layerReturns = LibMiddleware.beforeCall(msg.sig, msg.sender, msg.data, msg.value);
        _;
        LibMiddleware.afterCall(msg.sig, msg.sender, msg.data, msg.value, layerReturns);
    }
}
