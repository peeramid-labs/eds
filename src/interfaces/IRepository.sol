// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../libraries/LibSemver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IContractURI} from "./IContractURI.sol";
/**
 * @title IRepository Interface
 * @notice It is intended to be implemented by contracts that manage a collection of versions of a byte code.
 * @author Peeramid Labs, 2024
 */
interface IRepository is IERC165, IContractURI {
    /**
     * @notice Represents a source with version information, a unique identifier, and associated metadata.
     * @param version The version of the source, represented using the LibSemver.Version struct.
     * @param sourceId A unique identifier for the source.
     * @param metadata Additional data associated with the source.
     */
    struct Source {
        LibSemver.Version version;
        bytes32 sourceId;
        bytes metadata;
    }

    /**
     * @notice Error indicating that the specified version does not exist.
     * @param version The version number that does not exist.
     */
    error VersionDoesNotExist(uint256 version);
    /**
     * @notice Error indicating that a release with a zero value is not allowed.
     */
    error ReleaseZeroNotAllowed();
    /**
     * @notice Error indicating that the specified version already exists.
     * @param version The version number that already exists.
     */
    error VersionExists(uint256 version);
    /**
     * @notice Error indicating that the version increment is invalid.
     * @param version The version number that caused the error.
     * @dev The version increment must be exactly one for either major, minor, or patch.
     */
    error VersionIncrementInvalid(uint256 version);
    /**
     * @dev Error indicating that the release metadata is empty.
     */
    error EmptyReleaseMetadata();

    /**
     * @notice Emitted when a new version is added to the repository.
     * @param version The version number of the added item.
     * @param source The source identifier of the added item.
     * @param buildMetadata Additional metadata related to the build.
     */
    event VersionAdded(uint256 indexed version, bytes32 indexed source, bytes buildMetadata);
    /**
     * @notice Emitted when the metadata of a release is updated.
     * @param version The version number of the release.
     * @param releaseMetadata The metadata associated with the release.
     */
    event ReleaseMetadataUpdated(uint256 indexed version, bytes releaseMetadata);

    /**
     * @notice Updates the metadata for a specific release version.
     * @param version The version of the release to update.
     * @param releaseMetadata The new metadata to associate with the release.
     * @dev It MUST emit `ReleaseMetadataUpdated` event.
     */
    function updateReleaseMetadata(LibSemver.Version memory version, bytes calldata releaseMetadata) external;
    /**
     * @notice Retrieves the name of the repository.
     * @return The name of the repository as a bytes32 value.
     */
    function repositoryName() external view returns (bytes32);
    /**
     * @notice Creates a new release for the given source ID.
     * @param sourceId The unique identifier of the source.
     * @param metadata The metadata associated with the release.
     * @param version The semantic version of the new release.
     * @dev It MUST emit `VersionAdded` event.
     */
    function newRelease(bytes32 sourceId, bytes memory metadata, LibSemver.Version memory version) external;
    /**
     * @notice Retrieves the latest source.
     * @return The requested source
     */
    function getLatest() external view returns (Source memory);
    /**
     * @notice Retrieves a specific item from the repository.
     * @param required the required version
     * @return The requested `Source`.
     */
    function get(LibSemver.VersionRequirement calldata required) external view returns (Source memory);
}
