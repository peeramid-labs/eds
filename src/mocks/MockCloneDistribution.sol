// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import {ShortStrings, ShortString} from "@openzeppelin/contracts/utils/ShortStrings.sol";

import "../distributions/CloneDistribution.sol";

contract MockCloneDistribution is CloneDistribution {
    ShortString private immutable distributionName;
    uint256 private constant distributionVersion = 1;

    constructor() {
        distributionName = ShortStrings.toShortString("MockCloneDistribution");
    }

    function contractURI() external pure override returns (string memory) {
        return "MockCloneDistribution";
    }

    function instantiate(bytes memory) external override returns (address[] memory, bytes32, uint256) {
        return super._instantiate();
    }

    function sources() internal view virtual override returns (address[] memory, bytes32, uint256) {
        address[] memory source = new address[](1);
        source[0] = address(this);
        return (source, ShortString.unwrap(distributionName), distributionVersion);
    }
}
