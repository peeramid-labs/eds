// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import {IERC7746} from "../interfaces/IERC7746.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IRepository.sol";
import "../versioning/LibSemver.sol";
import {IERC7746} from "../interfaces/IERC7746.sol";
import "../interfaces/IMigration.sol";
enum MigrationStrategy {
    CALL,
    DELEGATECALL,
    REPOSITORY_MANGED
}
struct MigrationPlan {
    LibSemver.VersionRequirement from;
    LibSemver.VersionRequirement to;
    bytes32 migrationHash;
    MigrationStrategy strategy;
    bytes distributorCalldata;
    bytes32 distributionId;
}

/**
 * @title IDistributor Interface
 * @notice Defines the standard functions for a distributor contract.
 * @dev If you want to use {IRepository} for versioned distributions, use {IVersionDistributor} interface.
 * @author Peeramid Labs, 2024
 */
interface IDistributor is IERC7746, IERC165 {
    error InvalidVersionRequested(bytes32 distributionId, string version);
    error InvalidRepository(address repository);
    error RepositoryAlreadyExists(address repository);
    error VersionOutdated(bytes32 distributionId, string version);
    error InvalidApp(address app);
    error UnversionedDistribution(bytes32 distributionId);

    /**
     * @notice Emitted when the version of the distributor is changed.
     * @param distributionId The unique identifier of the distribution.
     * @param newRequirement The new version requirement (hashed for indexing).
     * @param newRequirementData The new version requirement data.
     */
    event VersionChanged(
        bytes32 indexed distributionId,
        LibSemver.VersionRequirement indexed newRequirement,
        LibSemver.VersionRequirement newRequirementData
    );

    /**
     * @notice Error indicating that an alias already exists.
     * @param aliasHash The hash of the alias that already exists.
     */
    error AliasAlreadyExists(bytes32 aliasHash);

    /**
     * @notice Error indicating that the distribution with the specified ID was not found.
     * @param id The unique identifier of the distribution that was not found.
     */
    error DistributionNotFound(bytes32 id);
    /**
     * @notice Error indicating that a distribution with the specified ID already exists.
     * @param id The unique identifier of the distribution that already exists.
     */
    error DistributionExists(bytes32 id);

    /**
     * @notice Error indicating that the initializer for the distribution was not found.
     * @param id The unique identifier of the distribution that was not found.
     */
    error InitializerNotFound(bytes32 id);

    /**
     * @notice Event emitted when a new distribution is instantiated.
     * @param distributionId The unique identifier of the distribution.
     * @param newAppId The unique identifier of the app.
     * @param version The version of the distribution, taken either from IDistribution or from IRepository.
     * @param appComponents The addresses of the app elements that were created.
     * @param args The arguments that were used for instantiation.
     * @dev It MUST emit when {IDistributor.instantiate} is called.
     */
    event Instantiated(
        bytes32 indexed distributionId,
        uint256 indexed newAppId,
        uint256 indexed version,
        address[] appComponents,
        bytes args
    );
    /**
     * @notice Event emitted when a distribution is disabled.
     * @param id The unique identifier of the distribution that was disabled.
     * @dev It MUST emit when {IDistributor.disableDistribution} is called.
     */
    event DistributionDisabled(bytes32 indexed id);

    /**
     * @notice Event emitted when a distribution is added.
     * @param id The unique identifier of the distribution that was added.
     * @param distribution The address of the distribution that was added.
     * @param initializer The address of the initializer for the distribution.
     * @dev It MUST emit when {IDistributor.addDistribution} is called.
     */
    event DistributionAdded(
        bytes32 indexed id,
        string indexed readableNameHashZ,
        address distribution,
        address indexed initializer,
        string readableName
    );

    /**
     * @notice Retrieves the unique identifiers of all distributions.
     * @return distributorIds An array of unique identifiers of all distributions.
     */
    function getDistributions() external view returns (bytes32[] memory distributorIds);

    /**
     * @notice Retrieves the URI of the distribution.
     * @param distributorId The unique identifier of the distribution.
     * @return uri The URI of the distribution.
     */
    function getDistributionURI(bytes32 distributorId) external view returns (string memory);

    /**
     * @notice Instantiates a new app with the given distributor ID and arguments.
     * @param distributorId The unique identifier of the distributor.
     * @param args The arguments to be used for instantiation.
     * @return app The addresses of the app that were created.
     * @return distributionName The name of the distribution.
     * @return distributionVersion The version of the distribution.
     * @dev It MUST emit {Instantiated} event.
     */
    function instantiate(
        bytes32 distributorId,
        bytes calldata args
    ) external payable returns (address[] memory, bytes32 distributionName, uint256 distributionVersion);

    /**
     * @notice Adds a new distribution with the specified distributor ID and initializer address.
     * @param distributorId The unique identifier for the distributor.
     * @param initializer The address of the initializer for the distribution.
     * @param readableName The readable name of the distribution.
     * @dev WARNING: If initializer is provided, it will DELEGATECALL to the initializer. Otherwise, instantiation arguments will be passed to the distribution for self-initialization. Initializer contract MUST be trusted by the distributor.
     */
    function addDistribution(bytes32 distributorId, address initializer, string memory readableName) external;

    /**
     * @notice Removes a distribution identified by the given distributorId.
     * @param distributorId The unique identifier of the distribution to be removed.
     */
    function disableDistribution(bytes32 distributorId) external;

    /**
     * @notice Retrieves the distribution ID associated with a given appComponent address.
     * @param appComponent The address of the appComponent for which the distribution ID is being requested.
     * @return The distribution ID as a bytes32 value.
     */
    function getDistributionId(address appComponent) external view returns (bytes32);
    /**
     * @notice Retrieves the unique identifier for a given appComponent address.
     * @param appComponent The address of the appComponent whose ID is to be retrieved.
     * @return The unique identifier (uint256) associated with the specified appComponent address.
     */
    function getAppId(address appComponent) external view returns (uint256);

    /**
     * @notice Adds a new versioned distribution to the repository.
     * @param repository The repository to which the distribution will be added.
     * @param initializer The address that initializes the distribution.
     * @param requirement The version requirements for the distribution.
     * @param readableName The readable name of the distribution.
     * @dev WARNING: If initializer is provided, it will DELEGATECALL to the initializer. Otherwise, instantiation arguments will be passed to the distribution for self-initialization. Initializer contract MUST be trusted by the distributor.
     */
    function addDistribution(
        IRepository repository,
        address initializer,
        LibSemver.VersionRequirement memory requirement,
        string memory readableName
    ) external;

    /**
     * @notice Changes the version requirement for a specific distribution.
     * @param distributionId The unique identifier of the distribution whose version requirement is to be changed.
     * @param newRequirement The new version requirement to be set for the distribution.
     */
    function changeVersion(bytes32 distributionId, LibSemver.VersionRequirement memory newRequirement) external;

    event MigrationContractAddedFromVersions(
        bytes32 indexed distributionId,
        uint256 indexed baseVersion,
        LibSemver.requirements indexed semanticRequirement,
        MigrationStrategy strategy,
        bytes32 migrationHash,
        bytes32 migrationId
    );
    event MigrationContractAddedToVersions(
        bytes32 indexed distributionId,
        bytes32 indexed migrationHash,
        LibSemver.requirements indexed semanticRequirement,
        MigrationStrategy strategy,
        uint256 baseVersion,
        bytes32 migrationId
    );

    event VersionMigrationRemoved(bytes32 indexed migrationId);

    function addVersionMigration(
        bytes32 distributionId,
        LibSemver.VersionRequirement memory from,
        LibSemver.VersionRequirement memory to,
        bytes32 migrationHash,
        MigrationStrategy strategy,
        bytes memory distributorCalldata
    ) external;

    function removeVersionMigration(bytes32 migrationId) external;

    function getVersionMigration(bytes32 migrationId) external view returns (MigrationPlan memory migrationPlan);

    function upgradeUserInstance(
        uint256 appId,
        bytes32 migrationId,
        bytes calldata userCalldata
    ) external returns (LibSemver.Version memory newVersion);

    function onDistributorChanged(
        uint256 appId,
        address newDistributor,
        bytes[] memory appData
    ) external returns (bool[] memory statuses, bytes[] memory results);

    error MigrationContractNotFound(bytes32 migrationId);
    error NotAnInstaller(address caller);
    error UntrustedInstaller(address caller);
    error MigrationAlreadyExists(bytes32 migrationId);
    error upgradeFailedWithPanic(uint errorCode);
    error upgradeFailedWithRevert(string reason);
    error upgradeFailedWithError(bytes reason);

    function getIdFromAlias(string memory readableName) external view returns (bytes32);
    function calculateDistributorId(address repository, address initializer) external pure returns (bytes32);
    error DistributionInstantiationFailed(bytes reason);
    error DistributionInstantiationPanic(uint errorCode);
    error DistributionInstantiationRevert(string reason);

    event DistributorChanged(uint256 appId, address newDistributor);
    event AppUpgraded(uint256 indexed appId, uint256 indexed oldVersion, uint256 indexed newVersion);
    event MigrationExecuted(
        bytes32 indexed migrationId,
        uint256 indexed oldVersion,
        uint256 indexed newVersion,
        bytes userCalldata
    );
    event UserUpgraded(
        uint256 indexed appId,
        bytes32 indexed migrationId,
        address indexed account,
        uint256 newVersion,
        uint256 oldVersion,
        bytes userCalldata
    );
}
