// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IAdminGetter Interface
 * @notice Provides a standard way to retrieve the admin address, particularly for wrapped proxies.
 * @dev Used in conjunction with proxies like WrappedTransparentUpgradeableProxy to allow specific callers (e.g., ProxyAdmin owner) to identify the proxy's admin.
 */
interface IAdminGetter {
    /**
     * @notice Retrieves the address of the proxy admin.
     * @dev This function is typically implemented in a proxy's fallback to respond only to specific callers (e.g., the ProxyAdmin owner).
     * @return adminAddress The address of the proxy admin.
     */
    function getWrappedProxyAdmin() external view returns (address adminAddress);
}
