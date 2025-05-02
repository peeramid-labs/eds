// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IAdminGetter.sol";

/**
 * @title MockTransferOwnershipProxy
 * @notice A simple mock contract for testing ownership transfer in onDistributorChanged
 * @dev This contract mocks both a proxy that supports getWrappedProxyAdmin() and a ProxyAdmin that has transferOwnership
 */
contract MockTransferOwnershipProxy is Ownable, IAdminGetter {
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Implements IAdminGetter interface, which returns self as the admin
     * @return Returns the address of this contract as the proxy admin
     */
    function getWrappedProxyAdmin() external view returns (address) {
        return address(this);
    }
}
