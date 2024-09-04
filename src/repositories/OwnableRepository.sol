// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../abstracts/Repository.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/IRepository.sol";
contract OwnableRepository is Repository, Ownable, ERC165 {
    constructor(address owner) Ownable(owner) {}

    function updateReleaseMetadata(LibSemver.Version memory version, bytes calldata releaseMetadata) public onlyOwner {
        super._updateReleaseMetadata(version, releaseMetadata);
    }
    function newRelease(bytes32 sourceId, bytes memory metadata, LibSemver.Version memory version) public onlyOwner {
        super._newRelease(sourceId, metadata, version);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IRepository).interfaceId || super.supportsInterface(interfaceId);
    }
}
