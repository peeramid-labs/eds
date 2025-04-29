// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../../src/interfaces/IRepository.sol";
import "../../src/versioning/LibSemver.sol";
import "../../src/erc7744/LibERC7744.sol";

contract MockRepository is IRepository {
    using LibERC7744 for bytes32;
    using LibSemver for LibSemver.Version;
    using LibSemver for LibSemver.VersionRequirement;

    mapping(uint256 => bytes32) private sources;
    mapping(uint256 => bytes) private sourceMetadata;
    mapping(uint64 => bytes32) private migrationScripts;
    bytes32 private _repositoryName = bytes32("MockRepository");

    // Mock functionality for testing
    address private mockMigrationScriptAddress;
    bytes private mockMigrationScriptCalldata;
    bool private shouldMock;

    function mock(string memory functionName, address addr, bytes memory callData) external {
        if (keccak256(abi.encodePacked(functionName)) == keccak256(abi.encodePacked("getMigrationScript"))) {
            mockMigrationScriptAddress = addr;
            mockMigrationScriptCalldata = callData;
            shouldMock = true;
        }
    }

    function addSource(LibSemver.Version memory version, bytes32 sourceId, bytes memory metadata) external {
        sources[version.toUint256()] = sourceId;
        sourceMetadata[version.toUint256()] = metadata;
    }

    function addMigrationScript(uint64 majorVersion, bytes32 migrationHash) external {
        migrationScripts[majorVersion] = migrationHash;
    }

    function resolveVersion(LibSemver.VersionRequirement calldata requirement) external view override returns (uint256) {
        // For simplicity, just return the exact version number from the requirement
        return requirement.version.toUint256();
    }

    function get(LibSemver.VersionRequirement calldata requirement) external view override returns (Source memory) {
        uint256 version = requirement.version.toUint256();
        bytes32 sourceId = sources[version];
        bytes memory metadata = sourceMetadata[version];
        if (sourceId == bytes32(0)) {
            // If no specific source is set, return a default
            sourceId = bytes32(uint256(uint160(address(this))));
        }
        return Source(requirement.version, sourceId, metadata);
    }

    function getLatest() external view override returns (Source memory) {
        // Just return a placeholder value
        LibSemver.Version memory latestVersion = LibSemver.parse(1);
        bytes32 sourceId = bytes32(uint256(uint160(address(this))));
        return Source(latestVersion, sourceId, "");
    }

    function getMigrationScript(uint64 majorVersion) external view override returns (bytes32) {
        if (shouldMock) {
            return bytes32(uint256(uint160(mockMigrationScriptAddress)));
        }
        return migrationScripts[majorVersion];
    }

    // Add a function to get the migration script calldata - not part of interface but needed for testing
    function getMigrationScriptCalldata() external view returns (bytes memory) {
        return mockMigrationScriptCalldata;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IRepository).interfaceId ||
            interfaceId == 0x01ffc9a7; // ERC165
    }

    function repositoryName() external view override returns (bytes32) {
        return _repositoryName;
    }

    function contractURI() external pure override returns (string memory) {
        return "ipfs://mockContract";
    }

    function updateReleaseMetadata(LibSemver.Version memory version, bytes calldata releaseMetadata) external override {
        sourceMetadata[version.toUint256()] = releaseMetadata;
        emit ReleaseMetadataUpdated(version.toUint256(), releaseMetadata);
    }

    function newRelease(bytes32 sourceId, bytes memory metadata, LibSemver.Version memory version, bytes32 migrationHash) external override {
        uint256 versionUint = version.toUint256();
        sources[versionUint] = sourceId;
        sourceMetadata[versionUint] = metadata;
        migrationScripts[version.major] = migrationHash;
        emit VersionAdded(versionUint, sourceId, metadata);
        emit MigrationScriptAdded(version.major, migrationHash);
    }

    function changeMigrationScript(uint64 majorVersion, bytes32 migrationHash) external override {
        migrationScripts[majorVersion] = migrationHash;
        emit MigrationScriptAdded(majorVersion, migrationHash);
    }
}