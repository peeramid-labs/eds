// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../middleware/ERC7746Hooked.sol";

/**
 * @title MockERC7746Hooked
 * @dev Mock contract for testing ERC7746Hooked modifiers
 */
contract MockERC7746Hooked is ERC7746Hooked {
    event FunctionCalled(bytes4 selector, address sender, bytes data, uint256 value);

    // Test value that can be set and retrieved
    string public testValue;

    // Called to test the ERC7746C modifier with explicit parameters
    function testModifierWithParams(
        bytes4 _selector,
        address _sender,
        bytes calldata _data,
        uint256 _value,
        string calldata newValue
    ) external ERC7746C(_selector, _sender, _data, _value) returns (bool) {
        testValue = newValue;
        emit FunctionCalled(_selector, _sender, _data, _value);
        return true;
    }

    // Called to test the ERC7746 modifier which uses msg values
    function testDefaultModifier(string calldata newValue) external payable ERC7746 returns (bool) {
        testValue = newValue;
        return true;
    }

    // Function without middleware for comparison
    function setValueWithoutMiddleware(string calldata newValue) external returns (bool) {
        testValue = newValue;
        return true;
    }

    // Getter for the current test value
    function getValue() external view returns (string memory) {
        return testValue;
    }
}
