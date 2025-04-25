// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IMigration.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../versioning/LibSemver.sol";
contract MockMigration is IMigration, ERC165 {
    using LibSemver for LibSemver.Version;
    constructor() {}
    event Migrated(address instance,uint256 from, uint256 to);
    function migrate(
        address[] memory instances,
        LibSemver.Version memory from,
        LibSemver.Version memory to,
        IRepository,
        bytes calldata,
        bytes calldata
    ) public {
        {
            for (uint256 i = 0; i < instances.length; i++) {
                emit Migrated(instances[i], from.toUint256(), to.toUint256());
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IMigration).interfaceId || super.supportsInterface(interfaceId);
    }
}
