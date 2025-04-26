// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IDistribution.sol";

contract MockFailingDistribution is IDistribution {
    function instantiate(bytes calldata args) external override returns (address[] memory, bytes32, uint256) {
        // Check if the args contain a specific "FAIL" string to trigger a revert
        if (args.length > 0 && keccak256(args) == keccak256(abi.encode(bytes32("FAIL")))) {
            revert("Intentional instantiation failure");
        }

        // Normal instantiation
        address[] memory instances = new address[](1);
        instances[0] = address(this);
        emit Distributed(msg.sender, instances);
        return (instances, bytes32("MockFailingDistribution"), 1);
    }

    function contractURI() external pure override returns (string memory) {
        return "ipfs://mockFailingDistribution";
    }

    function get() external view override returns (address[] memory, bytes32, uint256) {
        address[] memory sources = new address[](1);
        sources[0] = address(this);
        return (sources, bytes32("MockFailingDistribution"), 1);
    }
}