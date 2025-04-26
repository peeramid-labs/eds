// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../src/interfaces/IDistribution.sol";
import {ShortStrings, ShortString} from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract MockPanicDistribution is IDistribution {
    ShortString private immutable distributionName;
    uint256 private constant DISTRIBUTION_VERSION = 1;

    constructor() {
        distributionName = ShortStrings.toShortString("MockPanicDistribution");
    }

    function instantiate(bytes memory) external override returns (address[] memory instances, bytes32 name, uint256 version) {
        // This will cause a panic
        assert(false);

        // This code is unreachable but needed to compile
        instances = new address[](0);
        name = ShortString.unwrap(distributionName);
        version = DISTRIBUTION_VERSION;
    }

    function get() external view override returns (address[] memory sources, bytes32 name, uint256 version) {
        sources = new address[](1);
        sources[0] = address(this);
        name = ShortString.unwrap(distributionName);
        version = DISTRIBUTION_VERSION;
    }

    function contractURI() external pure returns (string memory) {
        return "ipfs://MockPanicDistribution";
    }
}