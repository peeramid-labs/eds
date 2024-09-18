// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;

interface IERC7746 {
    /// @notice Validates a function call before execution.
    /// @param configuration Layer-specific configuration data.
    /// @param selector The function selector being called.
    /// @param sender The address initiating the call.
    /// @param value The amount of ETH sent with the call (if any).
    /// @param data The calldata for the function call.
    /// @return beforeCallResult Arbitrary data to be passed to `afterCallValidation`.
    /// @dev MUST revert if validation fails.
    function beforeCall(
        bytes memory configuration,
        bytes4 selector,
        address sender,
        uint256 value,
        bytes memory data
    ) external returns (bytes memory);

    /// @notice Validates a function call after execution.
    /// @param configuration Layer-specific configuration data.
    /// @param selector The function selector being called.
    /// @param sender The address initiating the call.
    /// @param value The amount of ETH sent with the call (if any).
    /// @param data The calldata for the function call.
    /// @param beforeCallResult The data returned by `beforeCallValidation`.
    /// @dev MUST revert if validation fails.
    function afterCall(
        bytes memory configuration,
        bytes4 selector,
        address sender,
        uint256 value,
        bytes memory data,
        bytes memory beforeCallResult
    ) external;
}
