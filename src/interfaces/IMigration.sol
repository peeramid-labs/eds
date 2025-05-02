// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IRepository} from "./IRepository.sol";
import {LibSemver} from "../versioning/LibSemver.sol";

/**
 * @title IMigration
 * @notice Interface for migration contracts that handle version upgrades
 * @dev Implementations should perform the necessary state migrations between versions
 */
interface IMigration {
    /**
     * @notice Migrates instances from one version to another
     * @param instances Array of contract instances to migrate
     * @param oldVersion The semantic version being migrated from
     * @param newVersion The semantic version being migrated to
     * @param repository The repository to fetch additional data from
     * @param distributorCalldata Additional data provided by the distributor
     * @param userCalldata Additional data provided by the user
     */
    function migrate(
        address[] memory instances,
        LibSemver.Version memory oldVersion,
        LibSemver.Version memory newVersion,
        IRepository repository,
        bytes calldata distributorCalldata,
        bytes calldata userCalldata
    ) external;
}
