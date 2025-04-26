// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../../src/interfaces/IMigration.sol";
import "../../src/interfaces/IRepository.sol";
import "../../src/versioning/LibSemver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract MockMigration is IMigration, ERC165 {
    event MigrationExecuted(
        address[] instances,
        uint256 oldVersion,
        uint256 newVersion,
        bytes distributorCalldata,
        bytes userCalldata
    );

    function migrate(
        address[] memory instances,
        LibSemver.Version memory oldVersion,
        LibSemver.Version memory newVersion,
        IRepository repository,
        bytes calldata distributorCalldata,
        bytes calldata userCalldata
    ) external override {
        // Emit an event with migration details
        emit MigrationExecuted(
            instances,
            LibSemver.toUint256(oldVersion),
            LibSemver.toUint256(newVersion),
            distributorCalldata,
            userCalldata
        );

        // Don't do anything else - this is just a mock for testing
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IMigration).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}