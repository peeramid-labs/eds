// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.8;

import "../libraries/LibSemver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
interface IRepository is IERC165 {
    struct Source {
        LibSemver.Version version;
        bytes32 sourceId;
        bytes metadata;
    }

    error VersionDoesNotExist(uint256 version);
    error ReleaseZeroNotAllowed();
    error VersionExists(uint256 version);
    error VersionIncrementInvalid(uint256 version);
    error EmptyReleaseMetadata();
    error ReleaseDoesNotExist();
    event VersionAdded(uint256 indexed version, bytes32 indexed source, bytes buildMetadata);
    event ReleaseMetadataUpdated(uint256 indexed version, bytes releaseMetadata);

    function updateReleaseMetadata(LibSemver.Version memory version, bytes calldata releaseMetadata) external;
    function newRelease(bytes32 sourceId, bytes memory metadata, LibSemver.Version memory version) external;
    function getLatest() external view returns (Source memory);
    function get(
        LibSemver.Version calldata version,
        LibSemver.requirements requirement
    ) external view returns (Source memory);
}
