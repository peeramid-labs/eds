// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../src/interfaces/IDistribution.sol";
import {ShortStrings, ShortString} from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract MockFailingDistribution is IDistribution {
    ShortString private immutable distributionName;
    uint256 private constant DISTRIBUTION_VERSION = 1;

    constructor() {
        distributionName = ShortStrings.toShortString("MockFailingDistribution");
    }

    function instantiate(bytes memory args) external override returns (address[] memory instances, bytes32 name, uint256 version) {
        // Check if the args contain a specific "FAIL" string to trigger a revert
        if (args.length > 0 && keccak256(args) == keccak256(abi.encode(bytes32("FAIL")))) {
            revert("Intentional instantiation failure");
        }

        // Normal instantiation
        instances = new address[](1);
        instances[0] = address(this);
        emit Distributed(msg.sender, instances);
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
        return "ipfs://mockFailingDistribution";
    }
}