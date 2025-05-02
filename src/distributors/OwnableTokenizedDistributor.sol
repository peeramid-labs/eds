// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./TokenizedDistributor.sol";
import "../interfaces/IMigration.sol";
import "../versioning/LibSemver.sol";
import "../interfaces/IMigration.sol";
contract OwnableTokenizedDistributor is TokenizedDistributor, OwnableUpgradeable {
    constructor(
        address _owner,
        IERC20 _paymentToken,
        uint256 _defaultInstantiationCost,
        address _beneficiary
    ) TokenizedDistributor(_paymentToken, _defaultInstantiationCost, _beneficiary) {
        initialize(_owner);
    }

    function initialize(address _owner) public initializer {
        __Ownable_init(_owner);
    }

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
        super._addDistribution(address(repository), initializer, requirement, readableName);
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
        super._addVersionMigration(distributionId, from, to, migrationHash, strategy, distributorCalldata);
    }

    /**
     * @inheritdoc IDistributor
     */
    function removeVersionMigration(bytes32 migrationId) public onlyOwner {
        super._removeVersionMigration(migrationId);
    }

    function getDistribution(bytes32 distributionId) public view returns (DistributionComponent memory) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.distributionComponents[distributionId];
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

    function setInstantiationCost(bytes32 distributorsId, uint256 cost) public onlyOwner {
        super._setInstantiationCost(distributorsId, cost);
    }

    function setBeneficiary(address beneficiary) public onlyOwner {
        super._setBeneficiary(beneficiary);
    }
}
