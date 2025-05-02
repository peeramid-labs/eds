// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IDistributor} from "./IDistributor.sol";
import {IERC7746} from "../interfaces/IERC7746.sol";

struct App {
    address[] contracts;
    address middleware;
    bytes middlewareData;
}
/**
 * @title IInstaller Interface
 * @notice Enables target smart account to interact with Distributor contract ecosystem.
 */
interface IInstaller is IERC7746 {
    /**
     * @dev Error indicating that the provided address is not a valid app.
     * @param app The address that was checked and found not to be an app.
     */
    error NotAnApp(address app);

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
     * @notice Error indicating that distributor is whitelisted and hence it is not possible to selectively Disallow distributions.
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
     * @dev Emitted when an app is installed.
     * @param app The address of the installed app.
     * @param distributionId The identifier of the distribution.
     * @param permissions The permissions associated with the installation.
     * @param args Additional arguments related to the installation.
     * @dev MUST be emitted for every new app installed via `install` function.
     */
    event Installed(address indexed app, bytes32 indexed distributionId, bytes32 indexed permissions, bytes args);
    event Uninstalled(address indexed app);

    /**
     * @notice Installs a new app with the given distributor, distribution ID, and arguments.
     * @param distributor The distributor contract to be used for the installation.
     * @param distributionId The unique identifier for the distribution.
     * @param args Additional arguments required for the installation process.
     * @return appId The unique identifier of the newly installed app.
     * @dev MUST emit `Installed` event per installed app. MUST revert if the distributor is not whitelisted or the distribution is not allowed. MUST revert if the distributor is not a valid distributor.
     * @dev After successful installation ERC77446 hooks SHALL NOT revert if called by target, specifying active app in `sender` field.
     */
    function install(
        IDistributor distributor,
        bytes32 distributionId,
        bytes calldata args
    ) external payable returns (uint256 appId);

    /**
     * @notice Uninstalls an app with the given ID.
     * @param appId The unique identifier of the app to be uninstalled.
     * @dev MUST emit `Uninstalled` event per uninstalled app. MUST revert if the app is not installed.
     * @dev After successful uninstallation ERC77446 hooks SHALL revert if called by target, specifying uninstalled app in `sender` field.
     */
    function uninstall(uint256 appId) external;

    /**
     * @notice Retrieves the contracts associated with a specific app.
     * @param appId The unique identifier of the app.
     * @return app
     */
    function getApp(uint256 appId) external view returns (App memory app);

    /**
     * @notice Retrieves the number of apps.
     * @return The total number of apps as a uint256.
     * @dev this number SHALL NOT decrease after uninstallation.
     */
    function getAppsNum() external view returns (uint256);

    /**
     * @notice Checks if the given address is an active app.
     * @param app The address to check.
     * @return bool True if the address is an app, false otherwise.
     */
    function isApp(address app) external view returns (bool);

    /**
     * @notice Returns the distributor associated with a given app.
     * @param appComponent The address of the app for which the distributor is being queried.
     * @return The distributor associated with the specified app.
     */
    function distributorOf(address appComponent) external view returns (IDistributor);

    /**
     * @dev Emitted when the distributor of an app is changed.
     * @param appId The unique identifier of the app.
     * @param newDistributor The new distributor that replaced the previous one.
     */
    event DistributorChanged(uint256 indexed appId, IDistributor indexed newDistributor);
    /**
     * @notice Changes the distributor of a given app.
     * @param appId The unique identifier of the app.
     * @param newDistributor The new distributor to set for the app.
     * @dev MUST emit `DistributorChanged` event.
     */
    function changeDistributor(uint256 appId, IDistributor newDistributor, bytes[] memory appData) external;

    /**
     * @notice Retrieves the address of the target contract.
     * @return The address of the target contract.
     */
    function target() external view returns (address);

    /**
     * @dev Emitted when an app is upgraded.
     * @param appId The unique identifier of the app.
     * @param migrationId The unique identifier of the migration.
     * @param userCalldata Additional data required for the upgrade process.
     */
    event AppUpgraded(
        uint256 indexed appId,
        bytes32 indexed migrationId,
        uint256 indexed newVersion,
        bytes userCalldata
    );
    /**
     * @notice Upgrades an app with the given ID.
     * @param appId The unique identifier of the app to be upgraded.
     * @param migrationId The unique identifier of the migration to be applied.
     * @param userCalldata Additional data required for the upgrade process.
     * @dev MUST emit `AppUpgraded` event.
     */
    function upgradeApp(uint256 appId, bytes32 migrationId, bytes calldata userCalldata) external;
}
