// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IDistribution {
    event Distributed(address indexed distributor, address[] instances);

    function instantiate(
        bytes memory data
    ) external returns (address[] memory instances, bytes32 distributionName, uint256 distributionVersion);

    function get()
        external
        view
        returns (address[] memory sources, bytes32 distributionName, uint256 distributionVersion);

    function getMetadata() external view returns (string memory);
}
