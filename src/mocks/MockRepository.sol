// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IRepository.sol";
import "../versioning/LibSemver.sol";
import "../erc7744/LibERC7744.sol";
import "../repositories/Repository.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
contract MockRepository is Repository, ERC165 {

 constructor() Repository("name", "cURI") {}

    function updateReleaseMetadata(LibSemver.Version memory version, bytes calldata releaseMetadata) public  {
        super._updateReleaseMetadata(version, releaseMetadata);
    }
    function newRelease(bytes32 sourceId, bytes memory metadata, LibSemver.Version memory version, bytes32 migrationHash) public {
        _newRelease(sourceId, metadata, version, migrationHash);
    }

    function changeMigrationScript(uint64 major, bytes32 migrationHash) public {
        super._changeMigrationScript(major, migrationHash);
    }


    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IRepository).interfaceId || super.supportsInterface(interfaceId);
    }
}