// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../distributions/LatestVersionDistribution.sol";
import "../interfaces/IDistribution.sol";
import {ShortString, ShortStrings} from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract MockLatestVersionDistribution is LatestVersionDistribution {
    constructor(
        address repository_,
        string memory metadata_
    ) LatestVersionDistribution(IRepository(repository_), ShortStrings.toShortString(metadata_)) {}

    function sources() internal view override returns (address[] memory srcs, bytes32 name, uint256 version) {
        return super.sources();
    }

    function instantiate(
        bytes memory
    ) external override returns (address[] memory instances, bytes32 name, uint256 version) {
        return super._instantiate();
    }
}
