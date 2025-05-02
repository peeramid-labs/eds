// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IRepository.sol";
import "../versioning/LibSemver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * Simple mock repository for testing purposes
 */
contract MockRepository is IRepository, ERC165 {
    // Simple storage for one version
    bytes32 public sourceId;
    bytes32 public migrationHash;
    bytes public metadata;
    bytes32 private _repositoryName;

    constructor() {
        sourceId = bytes32(uint256(1));
        migrationHash = bytes32(0);
        _repositoryName = bytes32("MockRepository");
    }

    function newRelease(
        bytes32 _sourceId,
        bytes memory _metadata,
        LibSemver.Version calldata _version,
        bytes32 _migrationHash
    ) external {
        sourceId = _sourceId;
        metadata = _metadata;
        migrationHash = _migrationHash;
    }

    function changeMigrationScript(uint64, bytes32 _migrationHash) external {
        migrationHash = _migrationHash;
    }

    function get(LibSemver.VersionRequirement calldata) external view returns (IRepository.Source memory) {
        return
            IRepository.Source(
                LibSemver.Version(1, 0, 0), // version
                sourceId, // sourceId
                metadata // metadata
            );
    }

    function getLatest() external view returns (IRepository.Source memory) {
        return
            IRepository.Source(
                LibSemver.Version(1, 0, 0), // version
                sourceId, // sourceId
                metadata // metadata
            );
    }

    function getMigrationScript(uint64) external view returns (bytes32) {
        return migrationHash;
    }

    function repositoryName() external view returns (bytes32) {
        return _repositoryName;
    }

    function resolveVersion(LibSemver.VersionRequirement calldata) external pure returns (uint256) {
        return 1 << 128; // Major 1, minor 0, patch 0
    }

    function updateReleaseMetadata(LibSemver.Version calldata, bytes calldata _metadata) external {
        metadata = _metadata;
    }

    function contractURI() external pure returns (string memory) {
        return "MockRepositoryURI";
    }

    function name() external pure returns (string memory) {
        return "MockRepository";
    }

    function getLatestVersion(LibSemver.VersionRequirement calldata) external pure returns (LibSemver.Version memory) {
        return LibSemver.Version(1, 0, 0);
    }

    function getRelease(LibSemver.Version calldata) external view returns (bytes32, bytes memory) {
        return (sourceId, metadata);
    }

    function getMigration(uint64) external view returns (bytes32) {
        return migrationHash;
    }

    function getVersions() external pure returns (LibSemver.Version[] memory) {
        LibSemver.Version[] memory versions = new LibSemver.Version[](1);
        versions[0] = LibSemver.Version(1, 0, 0);
        return versions;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IRepository).interfaceId || super.supportsInterface(interfaceId);
    }
}
