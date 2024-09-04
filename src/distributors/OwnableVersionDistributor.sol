// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "../interfaces/IDistributor.sol";
import "../interfaces/IDistribution.sol";
import "../abstracts/CodeIndexer.sol";
import "../interfaces/IInitializer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../abstracts/VersionDistributor.sol";

contract OwnableVersionDistributor is VersionDistributor, Ownable {
    constructor(address _owner) Ownable(_owner) {}

    function instantiate(IRepository repository, bytes calldata args) public returns (address[] memory) {
        return super._instantiate(repository, args);
    }

    function addVersionedDistribution(
        IRepository repository,
        LibSemver.Version memory version,
        LibSemver.requirements requirement,
        bytes32 initializer
    ) public onlyOwner {
        super._addVersionedDistribution(repository, version, requirement, initializer);
    }

    function removeVersionedDistribution(IRepository repository) public onlyOwner {
        super._removeVersionedDistribution(repository);
    }

    function changeRequirement(
        IRepository repository,
        LibSemver.Version memory version,
        LibSemver.requirements requirement
    ) public onlyOwner {
        super._changeRequirement(repository, version, requirement);
    }
}
