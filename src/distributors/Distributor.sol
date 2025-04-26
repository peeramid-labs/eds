// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "../interfaces/IDistribution.sol";
import "../interfaces/IDistributor.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IInitializer.sol";
import "../erc7744/LibERC7744.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IContractURI} from "../interfaces/IContractURI.sol";
import "../interfaces/IMigration.sol";
import {MigrationPlan} from "../interfaces/IDistributor.sol";

/**
 * @title Distributor
 * @notice Abstract contract that implements the IDistributor interface, CodeIndexer, and ERC165.
 * This contract serves as a base for creating distributor contracts with specific functionalities.
 * It provides the necessary structure and functions to be extended by other contracts.
 * @author Peeramid Labs, 2024
 */
abstract contract Distributor is IDistributor, ERC165 {
    using LibERC7744 for address;
    using LibERC7744 for bytes32;
    using LibSemver for LibSemver.Version;
    struct DistributionComponent {
        address distributionLocation;
        address initializer;
    }

    struct VersionedDistribution {
        LibSemver.VersionRequirement requirement;
    }

    using EnumerableSet for EnumerableSet.Bytes32Set;
    mapping(bytes32 distributorsId => bool exists) public distributionExists;
    EnumerableSet.Bytes32Set private distributionsSet;
    mapping(address appComponent => uint256 appId) private appIds;
    mapping(uint256 appComponent => bytes32 distributorsId) public distributionOf;
    mapping(bytes32 distributorsId => DistributionComponent distribution) public distributionComponents;
    mapping(bytes32 distributorsId => LibSemver.VersionRequirement VersionRequirement) public versionRequirements;
    mapping(uint256 appId => LibSemver.Version appVersion) public appVersions;
    mapping(uint256 appId => address installer) public installers;
    mapping(uint256 appId => address[]) public appComponents;
    mapping(bytes32 migrationId => MigrationPlan migrationPlan) public migrations;
    mapping(bytes32 aliasHash => bytes32 distributorsId) public aliasToDistributorId;
    mapping(uint256 appId => address undergoingMigration) public appsUndergoingMigration;

    uint256 public numAppInstances;
    // @inheritdoc IDistributor
    function getDistributions() external view returns (bytes32[] memory) {
        return distributionsSet.values();
    }
    // @inheritdoc IDistributor
    function getDistributionId(address appComponent) external view virtual returns (bytes32) {
        return distributionOf[getAppId(appComponent)];
    }
    // @inheritdoc IDistributor
    function getAppId(address appComponent) public view virtual returns (uint256) {
        return appIds[appComponent];
    }
    // @inheritdoc IDistributor
    function getDistributionURI(bytes32 distributorsId) external view returns (string memory) {
        DistributionComponent memory distributionComponent = distributionComponents[distributorsId];
        return IContractURI(distributionComponent.distributionLocation).contractURI();
    }

    function _addDistribution(
        address repository,
        address initializer,
        LibSemver.VersionRequirement memory requirement,
        string memory readableName
    ) internal virtual returns (bytes32 distributorId) {
        if (!ERC165Checker.supportsInterface(address(repository), type(IRepository).interfaceId)) {
            revert InvalidRepository(repository);
        }
        distributorId = calculateDistributorId(repository, initializer);

        if (LibSemver.toUint256(requirement.version) == 0) {
            revert InvalidVersionRequested(distributorId, LibSemver.toString(requirement.version));
        }
        IRepository repositoryContract = IRepository(repository);
        require(repositoryContract.resolveVersion(requirement) != 0, "Version does not exist");
        _newDistributionRecord(distributorId, repository, initializer, readableName);
        versionRequirements[distributorId] = requirement;
        emit VersionChanged(distributorId, requirement, requirement);
    }

    function calculateDistributorId(address repository, address initializer) public pure returns (bytes32) {
        return keccak256(abi.encode(repository, initializer));
    }

    function calculateDistributorId(bytes32 codeHash, address initializer) public pure returns (bytes32) {
        return keccak256(abi.encode(codeHash, initializer));
    }

    function _newDistributionRecord(
        bytes32 distributorId,
        address source,
        address initializer,
        string memory readableName
    ) private {
        require(!distributionExists[distributorId], DistributionExists(distributorId));
        distributionExists[distributorId] = true;

        distributionsSet.add(distributorId);
        distributionComponents[distributorId] = DistributionComponent(source, initializer);
        bytes32 aliasHash = keccak256(abi.encode(readableName));
        if (aliasHash != bytes32(0)) {
            if (aliasToDistributorId[aliasHash] != bytes32(0)) {
                revert AliasAlreadyExists(aliasHash);
            }
            aliasToDistributorId[aliasHash] = distributorId;
        }
        emit DistributionAdded(distributorId, readableName, source, initializer, readableName);
    }
    function _addDistribution(
        bytes32 codeHash,
        address initializerAddress,
        string memory readableName
    ) internal virtual returns (bytes32 distributorId) {
        address distributionLocation = codeHash.getContainerOrThrow();
        if (distributionLocation == address(0)) revert DistributionNotFound(codeHash);
        distributorId = calculateDistributorId(codeHash, initializerAddress);
        _newDistributionRecord(distributorId, distributionLocation, initializerAddress, readableName);
    }

    function getIdFromAlias(string memory readableName) public view returns (bytes32) {
        return aliasToDistributorId[keccak256(abi.encode(readableName))];
    }

    function _disableDistribution(bytes32 distributorsId) internal virtual {
        if (!distributionsSet.contains(distributorsId)) revert DistributionNotFound(distributorsId);
        distributionsSet.remove(distributorsId);
        emit DistributionDisabled(distributorsId);
    }

    /**
     * @notice Internal function to instantiate a new appComponent.
     * @dev WARNING: This function will DELEGATECALL to initializer if such is provided. Initializer contract MUST be trusted by distributor.
     */
    function _instantiate(
        bytes32 distributorsId,
        bytes memory args
    )
        internal
        virtual
        returns (address[] memory newAppComponents, bytes32 distributionName, uint256 distributionVersion)
    {
        if (!distributionsSet.contains(distributorsId)) revert DistributionNotFound(distributorsId);
        DistributionComponent memory distributionComponent = distributionComponents[distributorsId];
        LibSemver.VersionRequirement memory versionRequirement = versionRequirements[distributorsId];

        // External initializer is provided, delegatecall to it
        // Contrary, if no initializer is provided, the distribution is expected to be self-initializing
        bool externallyInitialized = distributionComponent.initializer == address(0);
        bytes4 selector = IInitializer.initialize.selector;
        address distributionLocation;
        numAppInstances++;
        uint256 appId = numAppInstances;

        if (LibSemver.toUint256(versionRequirement.version) == 0) {
            // Unversioned distribution, expect IDistribution
            distributionLocation = distributionComponent.distributionLocation;
            // Unversioned distributions are considered to be at version 0
            appVersions[numAppInstances] = LibSemver.parse(0);
        } else {
            // Versioned distribution, expect IRepository
            IRepository repository = IRepository(distributionComponent.distributionLocation);
            IRepository.Source memory repoSource = repository.get(versionRequirement);
            distributionLocation = repoSource.sourceId.getContainerOrThrow();
            appVersions[numAppInstances] = repoSource.version;
        }
        try IDistribution(distributionLocation).instantiate(args) returns (
            address[] memory _newAppComponents,
            bytes32 _distributionName,
            uint256 _distributionVersion
        ) {
            newAppComponents = _newAppComponents;
            distributionName = _distributionName;
            distributionVersion = _distributionVersion;
        } catch Error(string memory reason) {
            revert(reason);
        } catch Panic(uint errorCode) {
            revert DistributionInstantiationPanic(errorCode);
        } catch (bytes memory lowLevelData) {
            revert DistributionInstantiationFailed(lowLevelData);
        }

        if (externallyInitialized) {
            (bool success, bytes memory result) = address(distributionComponent.initializer).delegatecall(
                abi.encodeWithSelector(selector, newAppComponents, args)
            );
            if (!success) {
                if (result.length > 0) {
                    assembly {
                        let returndata_size := mload(result)
                        revert(add(32, result), returndata_size)
                    }
                } else {
                    revert("initializer delegatecall failed without revert reason");
                }
            }
        }

        {
            uint256 instancesLength = newAppComponents.length;
            for (uint256 i; i < instancesLength; ++i) {
                appIds[newAppComponents[i]] = appId;
                distributionOf[appId] = distributorsId;
            }
        }
        emit Instantiated(distributorsId, appId, distributionVersion, newAppComponents, args);
        for (uint256 i; i < newAppComponents.length; i++) {
            appComponents[appId].push(newAppComponents[i]);
        }
        installers[appId] = msg.sender;
    }

    /**
     * @inheritdoc IERC7746
     * @notice This is ERC7746 hook must be called by appComponent methods that access scope is limited to the same appComponent or distribution
     * @dev it will revert if: (1) `msg.sender` is not a valid appComponent; (2) `maybeInstance` is not a valid appComponent (3) `appId` belongs to deactivate distribution
     */
    function beforeCall(
        bytes memory config,
        bytes4,
        address sender,
        uint256,
        bytes memory
    ) external view virtual returns (bytes memory) {
        address target = config.length > 0 ? abi.decode(config, (address)) : sender;
        bytes32 distributorsId = distributionOf[getAppId(sender)];
        uint256 appId = getAppId(sender);
        if (
            distributorsId != bytes32(0) && appsUndergoingMigration[appId] != address(0) && sender == appsUndergoingMigration[appId]
        ) {
            return abi.encode(distributorsId, ""); // Approve migration call
        }
        if (distributorsId != bytes32(0) && getAppId(target) == appId && distributionsSet.contains(distributorsId)) {
            // ToDo: This check could be based on DistributionOf, hence allowing cross-appComponent calls
            // Use layerConfig to allow client to configure requirement for the call
            if (!LibSemver.compare(appVersions[appId], versionRequirements[distributorsId])) {
                revert VersionOutdated(distributorsId, LibSemver.toString(appVersions[appId]));
            }
            return abi.encode(distributorsId, "");
        }
        revert InvalidApp(sender);
    }
    /**
     * @inheritdoc IERC7746
     * @notice This is ERC7746 hook must be called by appComponent methods that access scope is limited to the same appComponent or distribution
     * @dev it will revert if: (1) `msg.sender` is not a valid appComponent; (2) `maybeInstance` is not a valid appComponent (3) `appId` belongs to deactivate distribution
     */
    function afterCall(
        bytes memory config,
        bytes4,
        address sender,
        uint256,
        bytes memory,
        bytes memory
    ) external virtual {
        address target = config.length > 0 ? abi.decode(config, (address)) : msg.sender;
        bytes32 distributorsId = distributionOf[getAppId(sender)];
        uint256 appId = getAppId(sender);
        if (
            distributorsId != bytes32(0) && appsUndergoingMigration[appId] != address(0) && sender == appsUndergoingMigration[appId]
        ) {
            return; // Approve migration call
        }
        if ((getAppId(target) != getAppId(sender)) && distributionsSet.contains(distributorsId)) {
            revert InvalidApp(sender);
        }
        if (!LibSemver.compare(appVersions[appId], versionRequirements[distributorsId])) {
            revert VersionOutdated(distributorsId, LibSemver.toString(appVersions[appId]));
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IDistributor).interfaceId || super.supportsInterface(interfaceId);
    }

    function _changeVersion(bytes32 distributionId, LibSemver.VersionRequirement memory newRequirement) internal {
        if (!distributionsSet.contains(distributionId)) revert DistributionNotFound(distributionId);
        LibSemver.VersionRequirement memory oldRequirement = versionRequirements[distributionId];
        if (LibSemver.toUint256(oldRequirement.version) == 0) {
            revert UnversionedDistribution(distributionId);
        }
        if (LibSemver.toUint256(newRequirement.version) == 0) {
            revert InvalidVersionRequested(distributionId, LibSemver.toString(newRequirement.version));
        }
        if (LibSemver.areEqual(oldRequirement.version, newRequirement.version)) {
            revert InvalidVersionRequested(distributionId, LibSemver.toString(newRequirement.version));
        }
        versionRequirements[distributionId] = newRequirement;
        emit VersionChanged(distributionId, oldRequirement, newRequirement);
    }

    function _addVersionMigration(
        bytes32 distributionId,
        LibSemver.VersionRequirement memory from,
        LibSemver.VersionRequirement memory to,
        bytes32 migrationHash,
        MigrationStrategy strategy,
        bytes memory distributorCalldata
    ) internal {
        if (LibSemver.toUint256(versionRequirements[distributionId].version) == 0) {
            revert UnversionedDistribution(distributionId);
        }
        if(from.version.major == to.version.major)
         require(strategy != MigrationStrategy.REPOSITORY_MANGED, "Repository managed migration is not allowed for minor version migrations");
        bytes32 migrationId;
            migrationId = keccak256(abi.encode(distributionId, migrationHash, strategy));
            require(migrations[migrationId].distributionId == bytes32(0), MigrationAlreadyExists(migrationId));
            require(distributionComponents[distributionId].distributionLocation != address(0), "Distribution not found");
            require(from.version.major < to.version.major, "Major version mismatch");
            migrations[migrationId] = MigrationPlan(from, to, migrationHash, strategy, distributorCalldata, distributionId);

        emit MigrationContractAddedFromVersions(
            distributionId,
            from.version.toUint256(),
            from.requirement,
            strategy,
            migrationHash,
            migrationId
        );
        emit MigrationContractAddedToVersions(
            distributionId,
            migrationHash,
            to.requirement,
            strategy,
            to.version.toUint256(),
            migrationId
        );
    }
    function getVersionMigration(bytes32 migrationId) public view virtual returns (MigrationPlan memory migrationPlan) {
        return migrations[migrationId];
    }

    function _removeVersionMigration(bytes32 migrationId) internal virtual {
        migrations[migrationId].distributionId = bytes32(0);
        emit VersionMigrationRemoved(migrationId);
    }

    // @inheritdoc IDistributor
    function upgradeUserInstance(
        uint256 appId,
        bytes32 migrationId,
        bytes calldata userCalldata
    ) public returns (LibSemver.Version memory newVersion) {
        bytes32 distributorsId = distributionOf[appId];
        require(distributionsSet.contains(distributorsId), "Distribution not found");
        require(msg.sender == installers[appId], NotAnInstaller(msg.sender));
        require(versionRequirements[distributorsId].version.toUint256() != 0, "Not versioned");
        MigrationPlan memory migrationPlan = migrations[migrationId];
        require(LibSemver.compare(appVersions[appId], migrationPlan.from), "Version is not in range");

        require(migrationPlan.distributionId != bytes32(0), MigrationContractNotFound(migrationId));
        address[] memory _appComponents = appComponents[appId];
        LibSemver.Version memory oldVersion = appVersions[appId];
        DistributionComponent memory distributionComponent = distributionComponents[distributorsId];
        IRepository repository = IRepository(distributionComponent.distributionLocation);
        newVersion = LibSemver.parse(repository.resolveVersion(migrationPlan.to));
        address distributorMigrationContract = migrationPlan.migrationHash.getContainerOrThrow();
        appsUndergoingMigration[appId] = distributorMigrationContract;
        if (distributorMigrationContract != address(0)) {
            if (migrationPlan.strategy == MigrationStrategy.CALL) {
                try
                    IMigration(distributorMigrationContract).migrate(
                        _appComponents,
                        oldVersion,
                        newVersion,
                        repository,
                        migrationPlan.distributorCalldata,
                        userCalldata
                    )
                {} catch Error(string memory reason) {
                    revert upgradeFailedWithRevert(reason);
                } catch Panic(uint errorCode) {
                    revert upgradeFailedWithPanic(errorCode);
                } catch (bytes memory lowLevelData) {
                    revert upgradeFailedWithError(lowLevelData);
                }
            } else if (migrationPlan.strategy == MigrationStrategy.DELEGATECALL) {
                require(
                    ERC165Checker.supportsInterface(
                        distributorMigrationContract,
                        type(IMigration).interfaceId
                    ),
                    "Migration contract does not support IMigration interface"
                );
                (bool success, bytes memory result) = address(distributorMigrationContract).delegatecall(
                    abi.encodeWithSelector(
                        IMigration.migrate.selector,
                        _appComponents,
                        oldVersion,
                        newVersion,
                        repository,
                        migrationPlan.distributorCalldata,
                        userCalldata
                    )
                );
                if (!success) {
                    revert upgradeFailedWithError(result);
                }
            }
        } else if (migrationPlan.strategy == MigrationStrategy.REPOSITORY_MANGED) {
            // Repository managed migration, expect migration script to be provided by repository
            // NB: Migration scripts may be changed by repository.
            // This strategy assumes distributor trusts repository owner sufficiently to not change migration script maliciously.
            // This however is safe if repository implements timelocks and distributor hence can react to unexpected changes.
            // Rationale for not using CodeIndex here is that migration scripts may happen to have state (e.g. incentive counter for users to migrate)
            for (uint256 i = 0; i < migrationPlan.from.version.major - migrationPlan.to.version.major; i++) {
                bytes32 migrationHash = repository.getMigrationScript(uint64(migrationPlan.from.version.major + 1 + i));
                IMigration migration = IMigration(migrationHash.getContainerOrThrow());
                (bool success, bytes memory result) = address(migration).delegatecall(
                    abi.encodeWithSelector(
                        IMigration.migrate.selector,
                        _appComponents,
                        oldVersion,
                        newVersion,
                        repository,
                        migrationPlan.distributorCalldata,
                        userCalldata
                    )
                );
                if (!success) {
                    revert upgradeFailedWithError(result);
                }
            }
        }
        appsUndergoingMigration[appId] = address(0);
        uint256 oldVersionUint = oldVersion.toUint256();
        uint256 newVersionUint = newVersion.toUint256();
        appVersions[appId] = newVersion;
        emit UserUpgraded(appId, migrationId, msg.sender, newVersionUint, oldVersionUint, abi.encode(userCalldata));
        emit AppUpgraded(appId, oldVersionUint, newVersionUint);
        emit MigrationExecuted(migrationId, oldVersionUint, newVersionUint, abi.encode(userCalldata));
        return newVersion;
    }

    // @inheritdoc IDistributor
    function onDistributorChanged(
        uint256 appId,
        address newDistributor,
        bytes[] memory appData
    ) public returns (bool[] memory statuses, bytes[] memory results) {
        address[] memory _appComponents = appComponents[appId];
        delete distributionOf[appId];
        require(appData.length == _appComponents.length || appData.length == 0, "App data length mismatch");
        delete installers[appId];
        delete appComponents[appId];
        delete appVersions[appId];
        statuses = new bool[](_appComponents.length);
        results = new bytes[](_appComponents.length);
        for (uint256 i; i < _appComponents.length; i++) {
            // At this point Distributor does not care about app safety, app already is in full control by installer
            // We just allow installer to call from Distributor to finalize any ownership transfers (e.g. if using UpgradableProxy)
            if (appData.length > i) {
                (bool success, bytes memory result) = address(_appComponents[i]).call(appData[i]);
                statuses[i] = success;
                results[i] = result;
            } else {
                statuses[i] = true;
                results[i] = "";
            }
            delete appIds[_appComponents[i]];
        }
        emit DistributorChanged(appId, newDistributor);
        return (statuses, results);
    }
}
