// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../abstracts/CloneDistribution.sol";

contract MockCloneDistribution is CloneDistribution {
    function getMetadata() public pure override returns (string memory) {
        return "MockCloneDistribution";
    }

    function sources() internal view override returns (address[] memory, bytes32, uint256) {
        address[] memory source = new address[](1);
        source[0] = address(this);
        return (source, bytes32(abi.encodePacked("MockCloneDistribution")), 1);
    }
}
