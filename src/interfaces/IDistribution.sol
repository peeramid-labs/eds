// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDistribution {
    event Distributed(address indexed distributor, address[] instances);

    function instantiate() external returns (address[] memory instances);

    function getSources() external view returns (address[] memory);

    function getMetadata() external view returns (string memory);
}
