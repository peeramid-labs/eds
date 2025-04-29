// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IMigration.sol";
import "../interfaces/IRepository.sol";
import "../versioning/LibSemver.sol";
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
        IRepository ,
        bytes calldata distributorCalldata,
        bytes calldata userCalldata
    ) external override {
        uint256[] memory arrayToPanicOn = new uint256[](1);

        // Emit an event with migration details
        if(userCalldata.length > 0 && userCalldata[0] == 0xFF) revert("test revert");
        if(userCalldata.length > 0 && userCalldata[0] == 0xFE) arrayToPanicOn[20] = 111;
        if(userCalldata.length > 0 && userCalldata[0] == 0xFD) revert();

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
