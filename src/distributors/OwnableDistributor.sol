// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../abstracts/Distributor.sol";

contract OwnableDistributor is Distributor, Ownable {
    constructor(address _owner) Ownable(_owner) {}

    function instantiate(bytes32 id, bytes calldata args) external returns (address[] memory, bytes32, uint256) {
        return super._instantiate(id, args);
    }

    function addDistribution(bytes32 id, address initializer) external onlyOwner {
        super._addDistribution(id, initializer);
    }
    function addDistribution(
        IRepository repository,
        address initializer,
        LibSemver.VersionRequirement memory requirement
    ) external onlyOwner {
        super._addDistribution(address(repository), initializer, requirement);
    }

    function addNamedDistribution(bytes32 name, bytes32 distributorId, address initializer) external onlyOwner {
        super._addDistribution(name, distributorId, initializer);
    }

    function changeVersion(
        bytes32 distributionId,
        LibSemver.VersionRequirement memory newRequirement
    ) public onlyOwner {
        super._changeVersion(distributionId, newRequirement);
    }

    function removeDistribution(bytes32 id) public onlyOwner {
        super._removeDistribution(id);
    }

    function addVersionMigration(
        bytes32 distributionId,
        LibSemver.VersionRequirement memory from,
        LibSemver.VersionRequirement memory to,
        address migrationContract,
        MigrationStrategy strategy
    ) public onlyOwner {
        super._addVersionMigration(distributionId, from, to, migrationContract, strategy);
    }

}
