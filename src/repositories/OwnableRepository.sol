// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../repositories/Repository.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/IRepository.sol";
import "../interfaces/IMigration.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
contract OwnableRepository is Repository, Ownable, ERC165 {
    constructor(address owner, bytes32 name, string memory cURI) Ownable(owner) Repository(name, cURI) {}

    /**
     * @inheritdoc IRepository
     */
    function updateReleaseMetadata(LibSemver.Version memory version, bytes calldata releaseMetadata) public onlyOwner {
        super._updateReleaseMetadata(version, releaseMetadata);
    }
    /**
     * @inheritdoc IRepository
     */
    function newRelease(
        bytes32 sourceId,
        bytes memory metadata,
        LibSemver.Version memory version,
        bytes32 migrationHash
    ) public onlyOwner {
        super._newRelease(sourceId, metadata, version, migrationHash);
    }

    /**
     * @inheritdoc IRepository
     */
    function changeMigrationScript(uint64 major, bytes32 migrationHash) public onlyOwner {
        super._changeMigrationScript(major, migrationHash);
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IRepository).interfaceId || super.supportsInterface(interfaceId);
    }
}
