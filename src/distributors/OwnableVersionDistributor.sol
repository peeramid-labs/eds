// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../abstracts/VersionDistributor.sol";

contract OwnableVersionDistributor is VersionDistributor, Ownable {
    constructor(address _owner) Ownable(_owner) {}

    function instantiate(
        IRepository repository,
        bytes calldata args
    ) external returns (address[] memory, bytes32, uint256) {
        return super._instantiate(repository, args);
    }

    function addVersionedDistribution(
        IRepository repository,
        LibSemver.Version memory version,
        LibSemver.requirements requirement,
        address initializer
    ) external onlyOwner {
        super._addVersionedDistribution(repository, version, requirement, initializer);
    }

    function removeVersionedDistribution(IRepository repository) external onlyOwner {
        super._removeVersionedDistribution(repository);
    }

    function changeRequirement(
        IRepository repository,
        LibSemver.Version memory version,
        LibSemver.requirements requirement
    ) external onlyOwner {
        super._changeRequirement(repository, version, requirement);
    }
}
