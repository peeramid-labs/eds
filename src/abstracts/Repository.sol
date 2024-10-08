// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../libraries/LibSemver.sol";
import "../interfaces/IRepository.sol";

/**
 * @title Repository
 * @notice Abstract contract that implements the IRepository interface. This contract serves as a base for other contracts that require repository functionalities.
 */
abstract contract Repository is IRepository {
    bytes32 public immutable repositoryName;
    string private _cURI;
    using LibSemver for LibSemver.Version;
    mapping(uint256 => bytes32) internal versionedSources; // Flat version -> Source
    mapping(uint64 => bytes) internal releaseMetadata; // Major version -> Metadata
    mapping(uint128 => bytes) internal minorReleaseMetadata; // Major + Minor -> Metadata
    mapping(uint256 => bytes) internal patchReleaseMetadata; // Major + Minor + Patch -> Metadata
    mapping(uint64 => uint64) internal minorReleases;
    mapping(uint128 => uint128) internal patchReleases;
    uint64 internal majorReleases;
    uint256 internal latestVersion;

    constructor(bytes32 _repositoryName, string memory cURI) {
        repositoryName = _repositoryName;
        _cURI = cURI;
    }

    function _updateReleaseMetadata(LibSemver.Version memory version, bytes memory metadata) internal {
        uint256 versionFlat = version.toUint256();
        if (versionFlat == 0) revert VersionDoesNotExist(versionFlat);
        if (version.major > majorReleases) revert VersionDoesNotExist(versionFlat);
        if (version.minor > minorReleases[version.major]) revert VersionDoesNotExist(versionFlat);
        if (version.patch > patchReleases[(uint128(version.major) << 64) | uint128(version.minor)])
            revert VersionDoesNotExist(versionFlat);
        if (version.patch == 0) {
            if (version.minor == 0) {
                if (version.major == 0) revert ReleaseZeroNotAllowed();
                releaseMetadata[version.major] = metadata;
            } else {
                minorReleaseMetadata[(uint128(version.major) << 64) | uint128(version.minor)] = metadata;
            }
        } else {
            patchReleaseMetadata[versionFlat] = metadata;
        }
        emit ReleaseMetadataUpdated(versionFlat, metadata);
    }
    function _newRelease(bytes32 sourceId, bytes memory metadata, LibSemver.Version memory version) internal {
        uint256 versionFlat = version.toUint256();
        if (versionFlat == 0 && version.major == 0) revert ReleaseZeroNotAllowed();
        if (version.major > majorReleases) {
            if (version.major != majorReleases + 1) revert VersionIncrementInvalid(versionFlat);
            majorReleases = version.major;
            minorReleases[version.major] = 0;
            patchReleases[(uint128(version.major) << 64)] = 0;
            releaseMetadata[version.major] = metadata;
        } else if (version.minor > minorReleases[version.major]) {
            if (version.minor != minorReleases[version.major] + 1) revert VersionIncrementInvalid(versionFlat);
            minorReleases[version.major] = version.minor;
            patchReleases[(uint128(version.major) << 64) | uint128(version.minor)] = 0;
            minorReleaseMetadata[(uint128(version.major) << 64) | uint128(version.minor)] = metadata;
        } else if (version.patch > patchReleases[(uint128(version.major) << 64) | uint128(version.minor)]) {
            if (version.patch != patchReleases[(uint128(version.major) << 64) | uint128(version.minor)] + 1)
                revert VersionIncrementInvalid(versionFlat);
            patchReleases[(uint128(version.major) << 64) | uint128(version.minor)] = version.patch;
            patchReleaseMetadata[versionFlat] = metadata;
        } else {
            revert VersionExists(versionFlat);
        }
        versionedSources[versionFlat] = sourceId;
        latestVersion = versionFlat;
        emit VersionAdded(versionFlat, sourceId, metadata);
    }
    // @inheritdoc IRepository
    function getLatest() public view returns (Source memory) {
        Source memory src;
        src.sourceId = versionedSources[latestVersion];
        src.version = LibSemver.parse(latestVersion);
        src.metadata = releaseMetadata[uint64(latestVersion)];
        return src;
    }
    // @inheritdoc IRepository
    function get(LibSemver.VersionRequirement calldata required) public view returns (Source memory) {
        Source memory src;
        uint256 versionFlat = required.version.toUint256();
        uint256 resolvedVersion;
        if (required.version.major == 0) revert VersionDoesNotExist(versionFlat);
        if (required.requirement == LibSemver.requirements.EXACT) resolvedVersion = versionFlat;
        else if (required.requirement == LibSemver.requirements.MAJOR) {
            if (required.version.major > majorReleases) revert VersionDoesNotExist(required.version.toUint256());
            uint128 minorReleaseId = (uint128(required.version.major) << 64) |
                uint128(minorReleases[required.version.major]);
            resolvedVersion = (uint256(minorReleaseId) << 128) | uint256(patchReleases[minorReleaseId]);
            src.sourceId = versionedSources[resolvedVersion];
            src.version = LibSemver.parse(resolvedVersion);
        } else if (required.requirement == LibSemver.requirements.MAJOR_MINOR) {
            if (required.version.major > majorReleases) revert VersionDoesNotExist(required.version.toUint256());
            if (required.version.major == majorReleases) {
                if (required.version.minor > minorReleases[required.version.major])
                    revert VersionDoesNotExist(required.version.toUint256());
            }
            uint128 minorReleaseId = (uint128(required.version.major) << 64) | uint128(required.version.minor);
            resolvedVersion = (uint256(minorReleaseId) << 128) | uint256(patchReleases[minorReleaseId]);
        } else if (required.requirement == LibSemver.requirements.GREATER_EQUAL) {
            if (required.version.major > majorReleases) revert VersionDoesNotExist(required.version.toUint256());
            if (required.version.major == majorReleases) {
                if (required.version.minor > minorReleases[required.version.major])
                    revert VersionDoesNotExist(required.version.toUint256());
                if (required.version.minor == minorReleases[required.version.major]) {
                    if (
                        required.version.patch >
                        patchReleases[(uint128(required.version.major) << 64) | uint128(required.version.minor)]
                    ) revert VersionDoesNotExist(required.version.toUint256());
                }
            }
            uint128 minorReleaseId = (uint128(majorReleases) << 64) | uint128(minorReleases[majorReleases]);
            resolvedVersion = (uint256(minorReleaseId) << 128) | uint256(patchReleases[minorReleaseId]);
        } else if (required.requirement == LibSemver.requirements.GREATER) {
            if (required.version.major > majorReleases) revert VersionDoesNotExist(required.version.toUint256());
            if (required.version.major == majorReleases) {
                if (required.version.minor > minorReleases[required.version.major])
                    revert VersionDoesNotExist(required.version.toUint256());
                if (required.version.minor == minorReleases[required.version.major]) {
                    if (
                        required.version.patch >=
                        patchReleases[(uint128(required.version.major) << 64) | uint128(required.version.minor)]
                    ) revert VersionDoesNotExist(required.version.toUint256());
                }
            }
            uint128 minorReleaseId = (uint128(majorReleases) << 64) | uint128(minorReleases[majorReleases]);
            resolvedVersion = (uint256(minorReleaseId) << 128) | uint256(patchReleases[minorReleaseId]);
        } else if (required.requirement == LibSemver.requirements.LESSER_EQUAL) {
            revert("Not implemented");
        } else if (required.requirement == LibSemver.requirements.LESSER) {
            revert("Not implemented");
        } else if (required.requirement == LibSemver.requirements.ANY) {
            resolvedVersion = latestVersion;
        } else {
            revert VersionDoesNotExist(required.version.toUint256());
        }
        src.sourceId = versionedSources[resolvedVersion];
        src.version = LibSemver.parse(resolvedVersion);
        src.metadata = combineMetadata(resolvedVersion);
        assert(src.sourceId != bytes32(0));
        return src;
    }

    function combineMetadata(uint256 versionFlat) internal view returns (bytes memory) {
        LibSemver.Version memory version = LibSemver.parse(versionFlat);
        bytes memory majorMetadata = releaseMetadata[version.major];
        bytes memory minorMetadata = minorReleaseMetadata[(uint128(version.major) << 64) | uint128(version.minor)];
        bytes memory patchMetadata = patchReleaseMetadata[versionFlat];
        return bytes.concat(majorMetadata, minorMetadata, patchMetadata);
    }
    // @inheritdoc IRepository
    function getMajorReleaseMetadata(uint64 major) public view returns (bytes memory) {
        return releaseMetadata[major];
    }
    // @inheritdoc IRepository
    function getMinorReleaseMetadata(uint64 major, uint64 minor) public view returns (bytes memory) {
        return minorReleaseMetadata[(uint128(major) << 64) | uint128(minor)];
    }
    // @inheritdoc IRepository
    function getPatchReleaseMetadata(uint64 major, uint64 minor, uint64 patch) public view returns (bytes memory) {
        return patchReleaseMetadata[(uint256(major) << 192) | (uint256(minor) << 128) | uint256(patch)];
    }
    // @inheritdoc IRepository
    function getMajorReleases() public view returns (uint64) {
        return majorReleases;
    }
    // @inheritdoc IRepository
    function getMinorReleases(uint64 major) public view returns (uint64) {
        return minorReleases[major];
    }
    // @inheritdoc IRepository
    function getPatchReleases(uint64 major, uint64 minor) public view returns (uint128) {
        return patchReleases[(uint128(major) << 64) | uint128(minor)];
    }

    function contractURI() public view returns (string memory) {
        return _cURI;
    }
}
