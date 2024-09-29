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
     * @param distributionId The ID of the distribution being initialized
     * @param instances The addresses of the instances being initialized
     * @param distributionName The name of the distribution
     * @param distributionVersion The version of the distribution
     * @param args The additional arguments to be used for initialization
     */
    function initialize(
        bytes32 distributionId,
        address[] memory instances,
        bytes32 distributionName,
        uint256 distributionVersion,
        bytes calldata args
    ) external;
}
