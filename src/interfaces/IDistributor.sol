// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import {IERC7746} from "../interfaces/IERC7746.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
/**
 * @title IDistributor Interface
 * @notice Defines the standard functions for a distributor contract.
 * @dev If you want to use {IRepository} for versioned distributions, use {IVersionDistributor} interface.
 * @author Peeramid Labs, 2024
 */
interface IDistributor is IERC7746, IERC165 {
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
     * @notice Error indicating that the instance is invalid.
     * @param instance The address of the instance that is considered invalid.
     */
    error InvalidInstance(address instance);
    /**
     * @notice Event emitted when a new distribution is instantiated.
     * @param distributionId The unique identifier of the distribution.
     * @param instanceId The unique identifier of the instance.
     * @param argsHash The hash of the arguments used to instantiate the distribution.
     * @param instances The addresses of the instances that were created.
     * @dev It MUST emit when {IDistributor.instantiate} is called.
     */
    event Instantiated(
        bytes32 indexed distributionId,
        uint256 indexed instanceId,
        bytes indexed argsHash,
        address[] instances
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
     * @param initializer The address of the initializer that was added.
     * @dev It MUST emit when {IDistributor.addDistribution} is called.
     */
    event DistributionAdded(bytes32 indexed id, address indexed initializer);

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

    function addDistribution(bytes32 distributorId, address initializer) external;

    function removeDistribution(bytes32 distributorId) external;

    function getDistributionId(address instance) external view returns (bytes32);
    function getInstanceId(address instance) external view returns (uint256);
}
