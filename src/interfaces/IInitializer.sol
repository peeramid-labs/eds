// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IInitializer {
    event Initialized(address indexed container, bytes32 indexed codeHash);
    error initializationFailed(bytes32 id, string reason);

    function initialize(bytes32 distributionId, address[] memory instances, bytes32 distributionName, uint256 distributionVersion, bytes calldata args) external;
}
