// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;

// This file is exactly same as ./ICodeIndexer.sol\
// With exception for more loose pragma version
// Updating the CodeIndex pragma directly would cause changing the deployed bytecode for ERC7744
interface ICodeIndex {
    event Indexed(address indexed container, bytes32 indexed codeHash);
    error alreadyExists(bytes32 id, address source);

    function register(address container) external;

    function get(bytes32 id) external view returns (address);
}
