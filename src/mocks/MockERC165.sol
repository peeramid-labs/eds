// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title MockERC165
 * @dev A mock contract for testing that allows setting which interfaces are supported
 */
contract MockERC165 is ERC165 {
    mapping(bytes4 => bool) private _supportedInterfaces;

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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId] || super.supportsInterface(interfaceId);
    }
}
