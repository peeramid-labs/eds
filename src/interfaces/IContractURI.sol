// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IContractURI Interface
 * @notice Provides a standard function to retrieve contract-level metadata URI.
 * @dev See EIP-721 & EIP-1155 for related standards.
 */
interface IContractURI {
    /**
     * @notice Returns the Uniform Resource Identifier (URI) for contract-level metadata.
     * @return uri The URI string.
     */
    function contractURI() external view returns (string memory uri);
}
