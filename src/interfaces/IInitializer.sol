// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IInitializer
 * @notice Interface for the Initializer contract. This is intended to be used
 * as distribution initializer within the Distributor contract.
 */
interface IInitializer {
    event Initialized(address indexed container, bytes32 indexed codeHash);
    error initializationFailed(bytes32 id, string reason);

    /**
     * @notice Initializes the contract with necessary parameters.
     * @dev This function should be delegete-called by the distributor contract.
     * @param distribution The address of the distribution being initialized
     * @param distributionName The name of the distribution
     * @param distributionVersion The version of the distribution
     * @param userArgs The additional arguments to be used for initialization
     */
    function initialize(
        address distribution,
        bytes32 distributionName,
        uint256 distributionVersion,
        bytes calldata userArgs
    ) external returns (address[] memory instances);
}
