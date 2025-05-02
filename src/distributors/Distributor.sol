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
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {IAdminGetter} from "../interfaces/IAdminGetter.sol";
import {DistributorLayerConfig} from "../interfaces/IDistributor.sol";

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

    struct DistributorStore {
        EnumerableSet.Bytes32Set distributionsSet;
        mapping(address appComponent => uint256 appId) appIds;
        mapping(uint256 appId => address[]) appComponents;
        mapping(uint256 appId => address installer) installers;
        mapping(uint256 appId => bool renouncing) appsRenounced;
        mapping(bytes32 distributorsId => bool exists) distributionExists;
        mapping(uint256 appId => LibSemver.Version appVersion) appVersions;
        mapping(bytes32 migrationId => MigrationPlan migrationPlan) migrations;
        mapping(bytes32 aliasHash => bytes32 distributorsId) aliasToDistributorId;
        mapping(uint256 appId => address undergoingMigration) appsUndergoingMigration;
        mapping(uint256 appComponent => bytes32 distributorsId) distributionOf;
        mapping(bytes32 distributorsId => DistributionComponent distribution) distributionComponents;
        mapping(bytes32 distributorsId => LibSemver.VersionRequirement VersionRequirement) versionRequirements;
    }

    function appsRenounced(uint256 appId) public view returns (bool) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.appsRenounced[appId];
    }

    function appComponents(uint256 appId) public view returns (address[] memory) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.appComponents[appId];
    }

    function appVersions(uint256 appId) public view returns (LibSemver.Version memory) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.appVersions[appId];
    }

    function distributionOf(uint256 appId) public view returns (bytes32) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.distributionOf[appId];
    }

    function versionRequirements(bytes32 distributorsId) public view returns (LibSemver.VersionRequirement memory) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.versionRequirements[distributorsId];
    }

    function distributionComponents(bytes32 distributorsId) public view returns (DistributionComponent memory) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.distributionComponents[distributorsId];
    }

    function migrations(bytes32 migrationId) public view returns (MigrationPlan memory) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.migrations[migrationId];
    }

    function aliasToDistributorId(bytes32 aliasHash) public view returns (bytes32) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.aliasToDistributorId[aliasHash];
    }

    function appsUndergoingMigration(uint256 appId) public view returns (address) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.appsUndergoingMigration[appId];
    }

    function distributionExists(bytes32 distributorsId) public view returns (bool) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.distributionExists[distributorsId];
    }

    function installers(uint256 appId) public view returns (address) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.installers[appId];
    }

    using EnumerableSet for EnumerableSet.Bytes32Set;

    function getDistributorStore() internal pure returns (DistributorStore storage distributorStore) {
        bytes32 DISTRIBUTOR_STORAGE_POSITION = keccak256("distributor.distributor.store");
        assembly {
            distributorStore.slot := DISTRIBUTOR_STORAGE_POSITION
        }
    }

    uint256 public numAppInstances;
    // @inheritdoc IDistributor
    function getDistributions() external view returns (bytes32[] memory) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.distributionsSet.values();
    }
    // @inheritdoc IDistributor
    function getDistributionId(address appComponent) external view virtual returns (bytes32) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.distributionOf[getAppId(appComponent)];
    }
    // @inheritdoc IDistributor
    function getAppId(address appComponent) public view virtual returns (uint256) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.appIds[appComponent];
    }
    // @inheritdoc IDistributor
    function getDistributionURI(bytes32 distributorsId) external view returns (string memory) {
        DistributorStore storage distributorStore = getDistributorStore();
        DistributionComponent memory distributionComponent = distributorStore.distributionComponents[distributorsId];
        return IContractURI(distributionComponent.distributionLocation).contractURI();
    }

    function _addDistribution(
        address repository,
        address initializer,
        LibSemver.VersionRequirement memory requirement,
        string memory readableName
    ) internal virtual returns (bytes32 distributorId) {
        DistributorStore storage distributorStore = getDistributorStore();
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
        distributorStore.versionRequirements[distributorId] = requirement;
        emit VersionChanged(distributorId, requirement, requirement);
    }

    /**
     * @inheritdoc IDistributor
     */
    function calculateDistributorId(address repository, address initializer) public pure returns (bytes32) {
        return keccak256(abi.encode(repository, initializer));
    }

    /**
     * @inheritdoc IDistributor
     */
    function calculateDistributorId(bytes32 codeHash, address initializer) public pure returns (bytes32) {
        return keccak256(abi.encode(codeHash, initializer));
    }

    function _newDistributionRecord(
        bytes32 distributorId,
        address source,
        address initializer,
        string memory readableName
    ) private {
        DistributorStore storage distributorStore = getDistributorStore();
        require(!distributorStore.distributionExists[distributorId], DistributionExists(distributorId));
        distributorStore.distributionExists[distributorId] = true;
        distributorStore.distributionsSet.add(distributorId);
        distributorStore.distributionComponents[distributorId] = DistributionComponent(source, initializer);
        bytes32 aliasHash = keccak256(abi.encode(readableName));
        if (aliasHash != bytes32(0)) {
            if (distributorStore.aliasToDistributorId[aliasHash] != bytes32(0)) {
                revert AliasAlreadyExists(aliasHash);
            }
            distributorStore.aliasToDistributorId[aliasHash] = distributorId;
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
        require(
            ERC165Checker.supportsInterface(distributionLocation, type(IDistribution).interfaceId),
            "Distribution does not support IDistribution interface"
        );
        distributorId = calculateDistributorId(codeHash, initializerAddress);
        _newDistributionRecord(distributorId, distributionLocation, initializerAddress, readableName);
    }

    /**
     * @inheritdoc IDistributor
     */
    function getIdFromAlias(string memory readableName) public view returns (bytes32) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.aliasToDistributorId[keccak256(abi.encode(readableName))];
    }

    function _disableDistribution(bytes32 distributorsId) internal virtual {
        DistributorStore storage distributorStore = getDistributorStore();
        if (!distributorStore.distributionsSet.contains(distributorsId)) revert DistributionNotFound(distributorsId);
        distributorStore.distributionsSet.remove(distributorsId);
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
        DistributorStore storage distributorStore = getDistributorStore();
        if (!distributorStore.distributionsSet.contains(distributorsId)) revert DistributionNotFound(distributorsId);
        DistributionComponent memory distributionComponent = distributorStore.distributionComponents[distributorsId];
        LibSemver.VersionRequirement memory versionRequirement = distributorStore.versionRequirements[distributorsId];

        // External initializer is provided, delegatecall to it
        // Contrary, if no initializer is provided, the distribution is expected to be self-initializing
        bool externallyInitialized = distributionComponent.initializer != address(0);
        bytes4 selector = IInitializer.initialize.selector;
        address distributionLocation;
        numAppInstances++;
        uint256 appId = numAppInstances;

        if (LibSemver.toUint256(versionRequirement.version) == 0) {
            // Unversioned distribution, expect IDistribution
            distributionLocation = distributionComponent.distributionLocation;
            // Unversioned distributions are considered to be at version 0
            distributorStore.appVersions[numAppInstances] = LibSemver.parse(0);
        } else {
            // Versioned distribution, expect IRepository
            IRepository repository = IRepository(distributionComponent.distributionLocation);
            IRepository.Source memory repoSource = repository.get(versionRequirement);
            distributionLocation = repoSource.sourceId.getContainerOrThrow();
            distributionName = repository.repositoryName();
            distributionVersion = repoSource.version.toUint256();
            distributorStore.appVersions[numAppInstances] = repoSource.version;
        }
        if (!externallyInitialized) {
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
        } else {
            (bool success, bytes memory result) = address(distributionComponent.initializer).delegatecall(
                abi.encodeWithSelector(selector, distributionLocation, distributionName, distributionVersion, args)
            );
            if (!success) {
                revert(string(result));
            }

            newAppComponents = abi.decode(result, (address[]));
        }

        {
            uint256 instancesLength = newAppComponents.length;
            distributorStore.distributionOf[appId] = distributorsId;
            for (uint256 i; i < instancesLength; ++i) {
                distributorStore.appIds[newAppComponents[i]] = appId;
            }
        }
        emit Instantiated(distributorsId, appId, distributionVersion, newAppComponents, args);
        for (uint256 i; i < newAppComponents.length; i++) {
            distributorStore.appComponents[appId].push(newAppComponents[i]);
        }
        distributorStore.installers[appId] = msg.sender;
    }

    /**
     * @inheritdoc IERC7746
     * @notice This is ERC7746 hook must be called by appComponent methods that access scope is limited to the same appComponent or distribution
     * @dev it will revert if: (1) `msg.sender` is not a valid appComponent; (2) `maybeInstance` is not a valid appComponent (3) `appId` belongs to deactivate distribution
     */
    function beforeCall(
        bytes memory config,
        bytes4,
        address sender, // Sender is either the app accessing target or someone calling the app
        uint256,
        bytes memory
    ) external view virtual returns (bytes memory) {
        DistributorLayerConfig memory distConfig = abi.decode(config, (DistributorLayerConfig));
        DistributorStore storage distributorStore = getDistributorStore();
        uint256 appId = distributorStore.appIds[distConfig.app];
        bytes32 distributorsId = distributorStore.distributionOf[appId];
        address installer = distributorStore.installers[appId];
        if (distributorStore.appsRenounced[appId]) {
            return abi.encode(bytes32(0), "");
        }
        if (installer != msg.sender) {
            revert NotAnInstaller(msg.sender);
        }
        if (appId == 0 || !distributorStore.distributionsSet.contains(distributorsId)) {
            revert InvalidApp(sender, distributorsId, appId);
        }
        if (
            !LibSemver.compare(
                distributorStore.appVersions[appId],
                distributorStore.versionRequirements[distributorsId]
            )
        ) {
            revert VersionOutdated(distributorsId, LibSemver.toString(distributorStore.appVersions[appId]));
        }
        return abi.encode(distributorsId, "");
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
        DistributorLayerConfig memory distConfig = abi.decode(config, (DistributorLayerConfig));
        DistributorStore storage distributorStore = getDistributorStore();
        uint256 appId = distributorStore.appIds[distConfig.app];
        bytes32 distributorsId = distributorStore.distributionOf[appId];
        address installer = distributorStore.installers[appId];
        if (distributorStore.appsRenounced[appId]) {
            return;
        }
        if (installer != msg.sender) {
            revert NotAnInstaller(msg.sender);
        }
        if (appId == 0 || !distributorStore.distributionsSet.contains(distributorsId)) {
            revert InvalidApp(sender, distributorsId, appId);
        }
        if (
            !LibSemver.compare(
                distributorStore.appVersions[appId],
                distributorStore.versionRequirements[distributorsId]
            )
        ) {
            revert VersionOutdated(distributorsId, LibSemver.toString(distributorStore.appVersions[appId]));
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IDistributor).interfaceId || super.supportsInterface(interfaceId);
    }

    function _changeVersion(bytes32 distributionId, LibSemver.VersionRequirement memory newRequirement) internal {
        DistributorStore storage distributorStore = getDistributorStore();
        if (!distributorStore.distributionsSet.contains(distributionId)) revert DistributionNotFound(distributionId);
        LibSemver.VersionRequirement memory oldRequirement = distributorStore.versionRequirements[distributionId];
        if (LibSemver.toUint256(oldRequirement.version) == 0) {
            revert UnversionedDistribution(distributionId);
        }
        if (LibSemver.toUint256(newRequirement.version) == 0) {
            revert InvalidVersionRequested(distributionId, LibSemver.toString(newRequirement.version));
        }
        if (LibSemver.areEqual(oldRequirement.version, newRequirement.version)) {
            revert InvalidVersionRequested(distributionId, LibSemver.toString(newRequirement.version));
        }
        distributorStore.versionRequirements[distributionId] = newRequirement;
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
        DistributorStore storage distributorStore = getDistributorStore();
        if (LibSemver.toUint256(distributorStore.versionRequirements[distributionId].version) == 0) {
            revert UnversionedDistribution(distributionId);
        }
        if (from.version.major == to.version.major) {
            require(
                strategy != MigrationStrategy.REPOSITORY_MANAGED,
                "Repository managed migration is not allowed for minor version migrations"
            );
        }
        if (strategy == MigrationStrategy.REPOSITORY_MANAGED)
            require(migrationHash != bytes32(0), "Migration hash is required for repository managed migration");
        bytes32 migrationId;
        migrationId = keccak256(abi.encode(distributionId, migrationHash, strategy));
        require(
            distributorStore.migrations[migrationId].distributionId == bytes32(0),
            MigrationAlreadyExists(migrationId)
        );
        require(
            distributorStore.distributionComponents[distributionId].distributionLocation != address(0),
            "Distribution not found"
        );
        distributorStore.migrations[migrationId] = MigrationPlan(
            from,
            to,
            migrationHash,
            strategy,
            distributorCalldata,
            distributionId
        );

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
    /**
     * @inheritdoc IDistributor
     */
    function getVersionMigration(bytes32 migrationId) public view virtual returns (MigrationPlan memory migrationPlan) {
        DistributorStore storage distributorStore = getDistributorStore();
        return distributorStore.migrations[migrationId];
    }

    function _removeVersionMigration(bytes32 migrationId) internal virtual {
        DistributorStore storage distributorStore = getDistributorStore();
        distributorStore.migrations[migrationId].distributionId = bytes32(0);
        emit VersionMigrationRemoved(migrationId);
    }

    // @inheritdoc IDistributor
    function upgradeUserInstance(
        uint256 appId,
        bytes32 migrationId,
        bytes calldata userCalldata
    ) public virtual returns (LibSemver.Version memory newVersion) {
        DistributorStore storage distributorStore = getDistributorStore();
        bytes32 distributorsId = distributorStore.distributionOf[appId];
        require(distributorStore.distributionsSet.contains(distributorsId), "Distribution not found");
        require(msg.sender == distributorStore.installers[appId], NotAnInstaller(msg.sender));
        require(distributorStore.versionRequirements[distributorsId].version.toUint256() != 0, "Not versioned");
        MigrationPlan memory migrationPlan = distributorStore.migrations[migrationId];
        require(LibSemver.compare(distributorStore.appVersions[appId], migrationPlan.from), "Version is not in range");

        address[] memory _appComponents = distributorStore.appComponents[appId];
        LibSemver.Version memory oldVersion = distributorStore.appVersions[appId];
        DistributionComponent memory distributionComponent = distributorStore.distributionComponents[distributorsId];
        IRepository repository = IRepository(distributionComponent.distributionLocation);
        require(migrationPlan.distributionId != bytes32(0), MigrationContractNotFound(migrationId));
        newVersion = LibSemver.parse(repository.resolveVersion(migrationPlan.to));

        if (migrationPlan.strategy == MigrationStrategy.CALL) {
            address distributorMigrationContract = migrationPlan.migrationHash.getContainerOrThrow();
            distributorStore.appsUndergoingMigration[appId] = distributorMigrationContract;
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
            address distributorMigrationContract = migrationPlan.migrationHash.getContainerOrThrow();
            distributorStore.appsUndergoingMigration[appId] = distributorMigrationContract;
            require(
                ERC165Checker.supportsInterface(distributorMigrationContract, type(IMigration).interfaceId),
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
        } else if (migrationPlan.strategy == MigrationStrategy.REPOSITORY_MANAGED) {
            // Repository managed migration, expect migration script to be provided by repository
            // NB: Migration scripts may be changed by repository.
            // This strategy assumes distributor trusts repository owner sufficiently to not change migration script maliciously.
            // This however is safe if repository implements timelocks and distributor hence can react to unexpected changes.
            // Rationale for not using CodeIndex here is that migration scripts may happen to have state (e.g. incentive counter for users to migrate)
            for (uint256 i = 0; i < migrationPlan.to.version.major - migrationPlan.from.version.major; i++) {
                bytes32 migrationHash = repository.getMigrationScript(uint64(migrationPlan.from.version.major + 1 + i));
                IMigration migration = IMigration(migrationHash.getContainerOrThrow());
                distributorStore.appsUndergoingMigration[appId] = address(migration);
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
        distributorStore.appsUndergoingMigration[appId] = address(0);
        uint256 oldVersionUint = oldVersion.toUint256();
        uint256 newVersionUint = newVersion.toUint256();
        distributorStore.appVersions[appId] = newVersion;
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
        DistributorStore storage distributorStore = getDistributorStore();
        require(distributorStore.installers[appId] == msg.sender, "Not an installer");
        address[] memory _appComponents = distributorStore.appComponents[appId];
        require(appData.length == _appComponents.length || appData.length == 0, "App data length mismatch");
        require(!distributorStore.appsRenounced[appId], "App renounced");
        distributorStore.appsRenounced[appId] = true;
        statuses = new bool[](_appComponents.length);
        results = new bytes[](_appComponents.length);
        for (uint256 i; i < _appComponents.length; i++) {
            try IAdminGetter(address(_appComponents[i])).getWrappedProxyAdmin() returns (address proxyAdminAddress) {
                ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
                if (proxyAdmin.owner() == address(this)) {
                    address newOwner = newDistributor != address(0) ? newDistributor : msg.sender;
                    proxyAdmin.transferOwnership(newOwner);
                }
            } catch {
                // Does not have a proxy admin, ignore
            }

            // At this point Distributor does not care about app safety, app already is in full control by installer
            // We just allow installer to call from Distributor to finalize any ownership transfers (e.g. if using UpgradableProxy)
            if (appData.length > i) {
                (bool success, bytes memory result) = address(_appComponents[i]).call(appData[i]);
                statuses[i] = success;
                results[i] = result;
            } else {
                results[i] = "";
            }
            delete distributorStore.appIds[_appComponents[i]];
        }
        delete distributorStore.distributionOf[appId];
        delete distributorStore.installers[appId];
        delete distributorStore.appComponents[appId];
        delete distributorStore.appVersions[appId];
        emit DistributorChanged(appId, newDistributor);
        return (statuses, results);
    }
}
