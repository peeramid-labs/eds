// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import {IERC7746} from "../interfaces/IERC7746.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IRepository.sol";
import "../libraries/LibSemver.sol";
import {IERC7746} from "../interfaces/IERC7746.sol";

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
    error InvalidInstance(address instance);
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
     * @param newInstanceId The unique identifier of the instance.
     * @param version The version of the distribution, taken either from IDistribution or from IRepository.
     * @param instances The addresses of the instances that were created.
     * @param args The arguments that were used for instantiation.
     * @dev It MUST emit when {IDistributor.instantiate} is called.
     */
    event Instantiated(
        bytes32 indexed distributionId,
        uint256 indexed newInstanceId,
        uint256 indexed version,
        address[] instances,
        bytes args
    );
    /**
     * @notice Event emitted when a distribution is removed.
     * @param id The unique identifier of the distribution that was removed.
     * @dev It MUST emit when {IDistributor.removeDistribution} is called.
     */
    event DistributionRemoved(bytes32 indexed id);

    /**
     * @notice Event emitted when a distribution is added.
     * @param id The unique identifier of the distribution that was added.
     * @param distribution The address of the distribution that was added.
     * @param initializer The address of the initializer for the distribution.
     * @dev It MUST emit when {IDistributor.addDistribution} is called.
     */
    event DistributionAdded(bytes32 indexed id, address distribution, address indexed initializer);

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
     * @notice Instantiates a new instance with the given distributor ID and arguments.
     * @param distributorId The unique identifier of the distributor.
     * @param args The arguments to be used for instantiation.
     * @return instances The addresses of the instances that were created.
     * @return distributionName The name of the distribution.
     * @return distributionVersion The version of the distribution.
     * @dev It MUST emit {Instantiated} event.
     */
    function instantiate(
        bytes32 distributorId,
        bytes calldata args
    ) external returns (address[] memory, bytes32 distributionName, uint256 distributionVersion);

    /**
     * @notice Adds a new distribution with the specified distributor ID and initializer address.
     * @param distributorId The unique identifier for the distributor.
     * @param initializer The address of the initializer for the distribution.
     * @dev WARNING: If initializer is provided, it will DELEGATECALL to the initializer. Otherwise, instantiation arguments will be passed to the distribution for self-initialization. Initializer contract MUST be trusted by the distributor.
     */
    function addDistribution(bytes32 distributorId, address initializer) external;

    /**
     * @notice Removes a distribution identified by the given distributorId.
     * @param distributorId The unique identifier of the distribution to be removed.
     */
    function removeDistribution(bytes32 distributorId) external;

    /**
     * @notice Retrieves the distribution ID associated with a given instance address.
     * @param instance The address of the instance for which the distribution ID is being requested.
     * @return The distribution ID as a bytes32 value.
     */
    function getDistributionId(address instance) external view returns (bytes32);
    /**
     * @notice Retrieves the unique identifier for a given instance address.
     * @param instance The address of the instance whose ID is to be retrieved.
     * @return The unique identifier (uint256) associated with the specified instance address.
     */
    function getInstanceId(address instance) external view returns (uint256);

    /**
     * @notice Adds a new versioned distribution to the repository.
     * @param repository The repository to which the distribution will be added.
     * @param initializer The address that initializes the distribution.
     * @param requirement The version requirements for the distribution.
     * @dev WARNING: If initializer is provided, it will DELEGATECALL to the initializer. Otherwise, instantiation arguments will be passed to the distribution for self-initialization. Initializer contract MUST be trusted by the distributor.
     */
    function addDistribution(
        IRepository repository,
        address initializer,
        LibSemver.VersionRequirement memory requirement
    ) external;

    /**
     * @notice Changes the version requirement for a specific distribution.
     * @param distributionId The unique identifier of the distribution whose version requirement is to be changed.
     * @param newRequirement The new version requirement to be set for the distribution.
     */
    function changeVersion(bytes32 distributionId, LibSemver.VersionRequirement memory newRequirement) external;

    /**
     * @notice Adds a new versioned distribution to the repository.
     * @param name The name of the distribution.
     * @param distributorId The unique identifier of the distributor.
     * @param initializer The address that initializes the distribution.
     */
    function addNamedDistribution(bytes32 name, bytes32 distributorId, address initializer) external;
}
