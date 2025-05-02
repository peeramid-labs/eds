// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../versioning/LibSemver.sol";

contract LibSemverTest {
    function toUint256(LibSemver.Version memory _version) public pure returns (uint256) {
        return LibSemver.toUint256(_version);
    }

    function parse(uint256 _version) public pure returns (LibSemver.Version memory) {
        return LibSemver.parse(_version);
    }

    function versionToString(LibSemver.Version memory _version) public pure returns (string memory) {
        return LibSemver.toString(_version);
    }

    function require_exact(LibSemver.Version memory _version1, LibSemver.Version memory _version2) public pure {
        LibSemver.require_exact(_version1, _version2);
    }

    function require_major(LibSemver.Version memory _version1, LibSemver.Version memory _version2) public pure {
        LibSemver.require_major(_version1, _version2);
    }

    function require_major_minor(LibSemver.Version memory _version1, LibSemver.Version memory _version2) public pure {
        LibSemver.require_major_minor(_version1, _version2);
    }

    function require_greater_equal(LibSemver.Version memory _version1, LibSemver.Version memory _version2) public pure {
        LibSemver.require_greater_equal(_version1, _version2);
    }

    function require_greater(LibSemver.Version memory _version1, LibSemver.Version memory _version2) public pure {
        LibSemver.require_greater(_version1, _version2);
    }

    function require_lesser_equal(LibSemver.Version memory _version1, LibSemver.Version memory _version2) public pure {
        LibSemver.require_lesser_equal(_version1, _version2);
    }

    function require_lesser(LibSemver.Version memory _version1, LibSemver.Version memory _version2) public pure {
        LibSemver.require_lesser(_version1, _version2);
    }

    function areEqual(LibSemver.Version memory _version1, LibSemver.Version memory _version2) public pure returns (bool) {
        return LibSemver.areEqual(_version1, _version2);
    }

    function compare(
        LibSemver.Version memory has,
        LibSemver.VersionRequirement memory needs
    ) public pure returns (bool) {
        return LibSemver.compare(has, needs);
    }

    function getNextMajor(LibSemver.Version memory _version) public pure returns (LibSemver.Version memory) {
        return LibSemver.getNextMajor(_version);
    }

    function getNextMinor(LibSemver.Version memory _version) public pure returns (LibSemver.Version memory) {
        return LibSemver.getNextMinor(_version);
    }

    function getNextPatch(LibSemver.Version memory _version) public pure returns (LibSemver.Version memory) {
        return LibSemver.getNextPatch(_version);
    }
}