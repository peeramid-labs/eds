// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IDistributor} from "./IDistributor.sol";
import {IERC7746} from "../interfaces/IERC7746.sol";

/**
 * @title IInstaller Interface
 * @notice Enables target smart account to interact with Distributor contract ecosystem.
 */
interface IInstaller is IERC7746 {
    /**
     * @dev Error indicating that the provided address is not a valid instance.
     * @param instance The address that was checked and found not to be an instance.
     */
    error NotAnInstance(address instance);

    /**
     * @notice Error indicating that the provided distributor is invalid.
     * @param distributor The distributor that is considered invalid.
     */
    error InvalidDistributor(IDistributor distributor);
    /**
     * @dev Error indicating that the provided target address is not the smart account installer serves.
     * @param target The address that is considered invalid.
     */
    error InvalidTarget(address target);
    /**
     * @notice Error indicating that the specified distributor is already allowed.
     * @param distributor The distributor that is already allowed.
     */
    error alreadyAllowed(IDistributor distributor);
    /**
     * @notice Error indicating that a distribution is not permitted (not installed).
     * @param distributor The address of the distributor containing the distribution.
     * @param distributionId The unique identifier of the distribution.
     */
    error DistributionIsNotPermitted(IDistributor distributor, bytes32 distributionId);
    /**
     * @notice Error indicating that distributor is whitelisted and hence it is not possible to selectively Disallow distriributions.
     * @param distributor The whitelisted distributor.
     * @param distributionId The ID of the distribution that was attempted to Disallow.
     * @dev If getting this error: consider first removing distributor from whitelist, and then Disallowing the distribution.
     */
    error DisallowDistOnWhitelistedDistributor(IDistributor distributor, bytes32 distributionId);

    /**
     * @dev Emitted when a distributor is whitelisted.
     * @param distributor The address of the distributor that has been whitelisted.
     * @dev Any distribution of the whitelisted distributor MUST be allowed to be installed.
     */
    event DistributorWhitelisted(IDistributor indexed distributor);
    /**
     * @notice Emitted when a distributor is removed from the whitelist.
     * @param distributor The address of the distributor that was revoked.
     * @dev WARNING: After removal, the distributions that were allowed by id are still allowed.
     */
    event DistributorWhitelistRevoked(IDistributor indexed distributor);

    /**
     * @dev Emitted when a distribution is allowed by the installer.
     * @param distributor The address of the distributor that is allowed.
     * @param distributionId The unique identifier of the distribution.
     */
    event DistributionAllowed(IDistributor indexed distributor, bytes32 indexed distributionId);
    /**
     * @dev Emitted when a distribution is disallowed by the installer.
     * @param distributor The address of the distributor that is disallowed.
     * @param distributionId The unique identifier of the distribution that is disallowed.
     */
    event DistributionDisallowed(IDistributor indexed distributor, bytes32 indexed distributionId);

    /**
     * @notice Allows a specified distributor to distribute a given distribution ID.
     * @param distributor The address of the distributor hosting a distribution Id.
     * @param distributionId The ID of the distribution to be allowed.
     * @dev MUST emit `DistributionAllowed` event.
     */
    function allowDistribution(IDistributor distributor, bytes32 distributionId) external;

    /**
     * @notice Disallows a specific distribution from a given distributor.
     * @param distributor The address of the distributor contract.
     * @param distributionId The unique identifier of the distribution to be disallowed.
     * @dev MUST emit `DistributionDisallowed` event.
     */
    function disallowDistribution(IDistributor distributor, bytes32 distributionId) external;

    /**
     * @notice Retrieves the list of whitelisted distributions for a given distributor.
     * @param distributor The address of the distributor to query.
     * @return An array of bytes32 representing the whitelisted distributions.
     * @dev If the distributor is whitelisted, all distributions are allowed.
     */
    function whitelistedDistributions(IDistributor distributor) external view returns (bytes32[] memory);

    /**
     * @notice Adds a distributor to the whitelist.
     * @param distributor The address of the distributor to be whitelisted.
     * @dev After whitelisting, all distributions of the distributor are allowed. Must emit `DistributorWhitelisted` event.
     */
    function whitelistDistributor(IDistributor distributor) external;

    /**
     * @notice Revokes the whitelisted status of a given distributor.
     * @param distributor The address of the distributor to be revoked.
     * @dev After revoking, the distributions that were allowed by id are still allowed. Must emit `DistributorWhitelistRevoked` event.
     */
    function revokeWhitelistedDistributor(IDistributor distributor) external;

    /**
     * @notice Checks if the given address is a valid distributor.
     * @param distributor The address of the distributor to check.
     * @return bool Returns true if the address is a valid distributor, otherwise false.
     */
    function isDistributor(IDistributor distributor) external view returns (bool);

    /**
     * @notice Retrieves the list of whitelisted distributor addresses.
     * @return An array of addresses that are whitelisted as distributors.
     */
    function getWhitelistedDistributors() external view returns (address[] memory);

    /**
     * @dev Emitted when an instance is installed.
     * @param instance The address of the installed instance.
     * @param distributionId The identifier of the distribution.
     * @param permissions The permissions associated with the installation.
     * @param args Additional arguments related to the installation.
     * @dev MUST be emitted for every new instance installed via `install` function.
     */
    event Installed(address indexed instance, bytes32 indexed distributionId, bytes32 indexed permissions, bytes args);
    event Uninstalled(address indexed instance);

    /**
     * @notice Installs a new instance with the given distributor, distribution ID, and arguments.
     * @param distributor The distributor contract to be used for the installation.
     * @param distributionId The unique identifier for the distribution.
     * @param args Additional arguments required for the installation process.
     * @return instanceId The unique identifier of the newly installed instance.
     * @dev MUST emit `Installed` event per installed instance. MUST revert if the distributor is not whitelisted or the distribution is not allowed. MUST revert if the distributor is not a valid distributor.
     * @dev After succesfull installation ERC77446 hooks SHALL NOT revert if called by target, specifying active instance in `sender` field.
     */
    function install(
        IDistributor distributor,
        bytes32 distributionId,
        bytes calldata args
    ) external payable returns (uint256 instanceId);

    /**
     * @notice Uninstalls an instance with the given ID.
     * @param instanceId The unique identifier of the instance to be uninstalled.
     * @dev MUST emit `Uninstalled` event per uninstalled instance. MUST revert if the instance is not installed.
     * @dev After succesfull uninstallation ERC77446 hooks SHALL revert if called by target, specifying uninstalled instance in `sender` field.
     */
    function uninstall(uint256 instanceId) external;

    /**
     * @notice Retrieves the contracts associated with a specific instance.
     * @param instanceId The unique identifier of the instance.
     * @return instanceContracts An array of addresses representing the contracts of the instance.
     */
    function getInstance(uint256 instanceId) external view returns (address[] memory instanceContracts);

    /**
     * @notice Retrieves the number of instances.
     * @return The total number of instances as a uint256.
     * @dev this number SHALL NOT decrease after uninstallation.
     */
    function getInstancesNum() external view returns (uint256);

    /**
     * @notice Checks if the given address is an active instance.
     * @param instance The address to check.
     * @return bool True if the address is an instance, false otherwise.
     */
    function isInstance(address instance) external view returns (bool);

    /**
     * @notice Returns the distributor associated with a given instance.
     * @param instance The address of the instance for which the distributor is being queried.
     * @return The distributor associated with the specified instance.
     */
    function distributorOf(address instance) external view returns (IDistributor);

    /**
     * @notice Retrieves the address of the target contract.
     * @return The address of the target contract.
     */
    function target() external view returns (address);
}
