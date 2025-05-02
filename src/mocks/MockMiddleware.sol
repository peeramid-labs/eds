// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC7746.sol";

contract MockMiddleware is IERC7746 {
    bool public beforeCallCalled;
    bool public afterCallCalled;
    bytes public lastBeforeCallConfig;
    bytes4 public lastBeforeCallSelector;
    address public lastBeforeCallSender;
    uint256 public lastBeforeCallValue;
    bytes public lastBeforeCallData;

    bytes public lastAfterCallConfig;
    bytes4 public lastAfterCallSelector;
    address public lastAfterCallSender;
    uint256 public lastAfterCallValue;
    bytes public lastAfterCallData;
    bytes public lastAfterCallBeforeCallResult;

    bytes public beforeCallReturnValue;

    // Call order tracking
    bool public recordCallOrder;
    // Use a counter with a unique starting value for each middleware instance
    uint256 private callCounter;
    uint256 public beforeCallOrderValue;
    uint256 public afterCallOrderValue;

    // Counter to share between test instances (static-like behavior)
    uint256 private static_counter;

    constructor() {
        // Start with a non-zero value to avoid equality issues in tests
        callCounter = 1;
        static_counter = 1;
    }

    function setBeforeCallReturn(bytes memory value) external {
        beforeCallReturnValue = value;
    }

    function resetCounters() external {
        beforeCallCalled = false;
        afterCallCalled = false;
        callCounter = 1;
        static_counter = 1;
        beforeCallOrderValue = 0;
        afterCallOrderValue = 0;
    }

    function setRecordCallOrder(bool _recordCallOrder) external {
        recordCallOrder = _recordCallOrder;
        // Ensure counter starts with a non-zero value
        if (callCounter == 0) callCounter = 1;
        if (static_counter == 0) static_counter = 1;
    }

    function beforeCallOrder() external view returns (uint256) {
        return beforeCallOrderValue;
    }

    function afterCallOrder() external view returns (uint256) {
        return afterCallOrderValue;
    }

    function beforeCall(
        bytes memory configData,
        bytes4 selector,
        address sender,
        uint256 value,
        bytes memory data
    ) external override returns (bytes memory) {
        beforeCallCalled = true;
        lastBeforeCallConfig = configData;
        lastBeforeCallSelector = selector;
        lastBeforeCallSender = sender;
        lastBeforeCallValue = value;
        lastBeforeCallData = data;

        if (recordCallOrder) {
            // Use the static counter approach to ensure unique values across instances
            beforeCallOrderValue = static_counter++;
        }

        return beforeCallReturnValue;
    }

    function afterCall(
        bytes memory configData,
        bytes4 selector,
        address sender,
        uint256 value,
        bytes memory data,
        bytes memory beforeCallResult
    ) external override {
        afterCallCalled = true;
        lastAfterCallConfig = configData;
        lastAfterCallSelector = selector;
        lastAfterCallSender = sender;
        lastAfterCallValue = value;
        lastAfterCallData = data;
        lastAfterCallBeforeCallResult = beforeCallResult;

        if (recordCallOrder) {
            // Use the static counter approach to ensure unique values across instances
            afterCallOrderValue = static_counter++;
        }
    }

    function getLastBeforeCallArgs() external view returns (bytes memory configData, bytes4 selector, address sender, uint256 value, bytes memory data) {
        return (lastBeforeCallConfig, lastBeforeCallSelector, lastBeforeCallSender, lastBeforeCallValue, lastBeforeCallData);
    }

    function getLastAfterCallArgs() external view returns (bytes memory configData, bytes4 selector, address sender, uint256 value, bytes memory data, bytes memory beforeCallResult) {
        return (lastAfterCallConfig, lastAfterCallSelector, lastAfterCallSender, lastAfterCallValue, lastAfterCallData, lastAfterCallBeforeCallResult);
    }
}