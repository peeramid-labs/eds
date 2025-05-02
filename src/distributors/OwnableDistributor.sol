// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Distributor.sol";
import "../interfaces/IMigration.sol";
import "../versioning/LibSemver.sol";
import "../interfaces/IMigration.sol";
contract OwnableDistributor is Distributor, Ownable {
    constructor(address _owner) Ownable(_owner) {}

    /**
     * @inheritdoc IDistributor
     */
    function instantiate(
        bytes32 id,
        bytes calldata args
    ) external payable returns (address[] memory, bytes32, uint256) {
        return super._instantiate(id, args);
    }

    /**
     * @inheritdoc IDistributor
     */
    function addDistribution(bytes32 id, address initializer, string memory readableName) external onlyOwner {
        super._addDistribution(id, initializer, readableName);
    }
    /**
     * @inheritdoc IDistributor
     */
    function addDistribution(
        IRepository repository,
        address initializer,
        LibSemver.VersionRequirement memory requirement,
        string memory readableName
    ) external onlyOwner {
        _addDistribution(address(repository), initializer, requirement, readableName);
    }

    /**
     * @inheritdoc IDistributor
     */
    function changeVersion(
        bytes32 distributionId,
        LibSemver.VersionRequirement memory newRequirement
    ) public onlyOwner {
        super._changeVersion(distributionId, newRequirement);
    }

    /**
     * @inheritdoc IDistributor
     */
    function disableDistribution(bytes32 id) public onlyOwner {
        super._disableDistribution(id);
    }

    /**
     * @inheritdoc IDistributor
     */
    function addVersionMigration(
        bytes32 distributionId,
        LibSemver.VersionRequirement memory from,
        LibSemver.VersionRequirement memory to,
        bytes32 migrationHash,
        MigrationStrategy strategy,
        bytes memory distributorCalldata
    ) public onlyOwner {
        _addVersionMigration(distributionId, from, to, migrationHash, strategy, distributorCalldata);
    }

    /**
     * @inheritdoc IDistributor
     */
    function removeVersionMigration(bytes32 migrationId) public onlyOwner {
        _removeVersionMigration(migrationId);
    }

    function getDistribution(bytes32 distributionId) public view returns (DistributionComponent memory) {
        return distributionComponents[distributionId];
    }

    /**
     * @inheritdoc IDistributor
     */
    function upgradeUserInstance(
        uint256 appId,
        bytes32 migrationId,
        bytes calldata userCalldata
    ) public virtual override returns (LibSemver.Version memory) {
        return super.upgradeUserInstance(appId, migrationId, userCalldata);
    }
}
