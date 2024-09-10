// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.8;

import "../libraries/LibSemver.sol";
import "../interfaces/IRepository.sol";

abstract contract Repository is IRepository {

    bytes32 immutable public repositoryName;
    struct Uint64WithMetadata {
        uint64 value;
        bytes metadata;
    }
    struct Uint128WIthMetadata {
        uint128 value;
        bytes metadata;
    }
    using LibSemver for LibSemver.Version;
    mapping(uint256 => bytes32) internal versionedSources; // Flat version -> Source
    mapping(uint64 => bytes) internal releaseMetadata; // Major version -> Metadata
    mapping(uint128 => bytes) internal minorReleaseMetadata; // Major + Minor -> Metadata
    mapping(uint256 => bytes) internal patchReleaseMetadata; // Major + Minor + Patch -> Metadata
    mapping(uint64 => uint64) internal minorReleases;
    mapping(uint128 => uint128) internal patchReleases;
    mapping(bytes32 => uint256) internal sourceVersions;
    uint64 internal majorReleases;
    uint256 internal latestVersion;

    constructor(bytes32 _repositoryName) {
        repositoryName = _repositoryName;
    }
    // error VersionHashDoesNotExist(uint256 version);
    // error ReleaseZeroNotAllowed();
    // error AlreadyInPreviousRelease(uint256 version, bytes32 source);
    // error EmptyReleaseMetadata();
    // error ReleaseDoesNotExist();
    // event VersionAdded(uint256 indexed version, bytes32 indexed source, bytes buildMetadata);
    // event ReleaseMetadataUpdated(uint256 indexed version, bytes releaseMetadata);

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
    function getLatest() public view returns (Source memory) {
        Source memory src;
        src.sourceId = versionedSources[latestVersion];
        src.version = LibSemver.parse(latestVersion);
        src.metadata = releaseMetadata[uint64(latestVersion)];
        return src;
    }
    function get(
        LibSemver.Version memory version,
        LibSemver.requirements requirement
    ) public view returns (Source memory) {
        Source memory src;
        uint256 versionFlat = version.toUint256();
        uint256 resolvedVersion;
        if (version.major == 0) revert VersionDoesNotExist(versionFlat);
        if (requirement == LibSemver.requirements.EXACT) resolvedVersion = versionFlat;
        else if (requirement == LibSemver.requirements.MAJOR) {
            if (version.major > majorReleases) revert VersionDoesNotExist(version.toUint256());
            uint128 minorReleaseId = (uint128(version.major) << 64) | uint128(minorReleases[version.major]);
            resolvedVersion = (uint256(minorReleaseId) << 128) | uint256(patchReleases[minorReleaseId]);
            src.sourceId = versionedSources[resolvedVersion];
            src.version = LibSemver.parse(resolvedVersion);
        } else if (requirement == LibSemver.requirements.MAJOR_MINOR) {
            if (version.major > majorReleases) revert VersionDoesNotExist(version.toUint256());
            if (version.major == majorReleases) {
                if (version.minor > minorReleases[version.major]) revert VersionDoesNotExist(version.toUint256());
            }
            uint128 minorReleaseId = (uint128(version.major) << 64) | uint128(version.minor);
            resolvedVersion = (uint256(minorReleaseId) << 128) | uint256(patchReleases[minorReleaseId]);
        } else if (requirement == LibSemver.requirements.GREATER_EQUAL) {
            if (version.major > majorReleases) revert VersionDoesNotExist(version.toUint256());
            if (version.major == majorReleases) {
                if (version.minor > minorReleases[version.major]) revert VersionDoesNotExist(version.toUint256());
                if (version.minor == minorReleases[version.major]) {
                    if (version.patch > patchReleases[(uint128(version.major) << 64) | uint128(version.minor)])
                        revert VersionDoesNotExist(version.toUint256());
                }
            }
            uint128 minorReleaseId = (uint128(majorReleases) << 64) | uint128(minorReleases[majorReleases]);
            resolvedVersion = (uint256(minorReleaseId) << 128) | uint256(patchReleases[minorReleaseId]);
        } else if (requirement == LibSemver.requirements.GREATER) {
            if (version.major > majorReleases) revert VersionDoesNotExist(version.toUint256());
            if (version.major == majorReleases) {
                if (version.minor > minorReleases[version.major]) revert VersionDoesNotExist(version.toUint256());
                if (version.minor == minorReleases[version.major]) {
                    if (version.patch >= patchReleases[(uint128(version.major) << 64) | uint128(version.minor)])
                        revert VersionDoesNotExist(version.toUint256());
                }
            }
            uint128 minorReleaseId = (uint128(majorReleases) << 64) | uint128(minorReleases[majorReleases]);
            resolvedVersion = (uint256(minorReleaseId) << 128) | uint256(patchReleases[minorReleaseId]);
        } else if (requirement == LibSemver.requirements.LESSER_EQUAL) {
            revert("Not implemented");
        } else if (requirement == LibSemver.requirements.LESSER) {
            revert("Not implemented");
        } else if (requirement == LibSemver.requirements.ANY) {
            resolvedVersion = latestVersion;
        } else {
            revert VersionDoesNotExist(version.toUint256());
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

    function privateEnforceHasVersion(LibSemver.Version memory version) private view {
        uint64 _majorReleases = majorReleases;
        uint64 _minorReleases = minorReleases[version.major];
        uint128 _patchReleases = patchReleases[(uint128(version.major) << 64) | uint128(version.minor)];

        if (version.major > _majorReleases) revert VersionDoesNotExist(version.toUint256());
        if (version.major == _majorReleases) {
            if (version.minor > _minorReleases) revert VersionDoesNotExist(version.toUint256());
            if (version.minor == _minorReleases) {
                if (version.patch < _patchReleases) revert VersionDoesNotExist(version.toUint256());
            }
        }
    }
    function getMajorReleaseMetadata(uint64 major) public view returns (bytes memory) {
        return releaseMetadata[major];
    }
    function getMinorReleaseMetadata(uint64 major, uint64 minor) public view returns (bytes memory) {
        return minorReleaseMetadata[(uint128(major) << 64) | uint128(minor)];
    }
    function getPatchReleaseMetadata(uint64 major, uint64 minor, uint64 patch) public view returns (bytes memory) {
        return patchReleaseMetadata[(uint256(major) << 192) | (uint256(minor) << 128) | uint256(patch)];
    }
    function getMajorReleases() public view returns (uint64) {
        return majorReleases;
    }
    function getMinorReleases(uint64 major) public view returns (uint64) {
        return minorReleases[major];
    }
    function getPatchReleases(uint64 major, uint64 minor) public view returns (uint128) {
        return patchReleases[(uint128(major) << 64) | uint128(minor)];
    }
}
