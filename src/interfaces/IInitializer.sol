// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IInitializer {
    event Initialized(address indexed container, bytes32 indexed codeHash);
    error initializationFailed(bytes32 id, string reason);

    function initialize(bytes32 id, address[] memory instances, bytes calldata args) external;
}
