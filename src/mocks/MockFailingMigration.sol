// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../src/interfaces/IMigration.sol";
import "../../src/interfaces/IRepository.sol";
import "../../src/versioning/LibSemver.sol";

/**
 * @title MockFailingMigration
 * @dev A mock migration contract that always fails during migration for testing error handling
 */
contract MockFailingMigration is IMigration {
    /**
     * @dev Implements the migrate function of IMigration but always reverts
     */
    function migrate(
        address[] memory,
        LibSemver.Version memory,
        LibSemver.Version memory,
        IRepository,
        bytes calldata,
        bytes calldata
    ) external override {
        // Always revert
        revert("Migration failed intentionally");
    }

    /**
     * @dev Required to support ERC165 interface detection
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IMigration).interfaceId;
    }
}
