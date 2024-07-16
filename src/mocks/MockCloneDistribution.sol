// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../abstracts/CloneDistribution.sol";

contract MockCloneDistribution is CloneDistribution {
    function getMetadata() public pure override returns (string memory) {
        return "MockCloneDistribution";
    }

    function sources() internal view override returns (address[] memory) {
        address[] memory source = new address[](1);
        source[0] = address(this);
        return source;
    }
}
