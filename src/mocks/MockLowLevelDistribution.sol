// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IDistribution.sol";

contract MockLowLevelDistribution is IDistribution {
    function instantiate(bytes calldata) external override returns (address[] memory, bytes32, uint256) {
        // Force a low-level error using inline assembly
        assembly {
            invalid() // This generates a low-level error
        }

        // This code is unreachable due to the low-level error above
        address[] memory instances = new address[](1);
        instances[0] = address(this);
        emit Distributed(msg.sender, instances);
        return (instances, bytes32("MockLowLevelDistribution"), 1);
    }

    function contractURI() external pure override returns (string memory) {
        return "ipfs://mockLowLevelDistribution";
    }

    function get() external view override returns (address[] memory, bytes32, uint256) {
        address[] memory sources = new address[](1);
        sources[0] = address(this);
        return (sources, bytes32("MockLowLevelDistribution"), 1);
    }
}