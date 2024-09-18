// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";
library LibSemver {
    error versionMissmatch(string message);
    struct Version {
        uint64 major;
        uint64 minor;
        uint128 patch;
    }

    enum requirements {
        ANY, // *
        EXACT, // =
        MAJOR, // ^
        MAJOR_MINOR, // ~
        GREATER_EQUAL, // >=
        GREATER, // >
        LESSER_EQUAL, // <=
        LESSER // <
    }

    function toUint256(Version memory _version) internal pure returns (uint256) {
        return (uint256(_version.major) << 192) | (uint256(_version.minor) << 128) | uint256(_version.patch);
    }

    function parse(uint256 _version) internal pure returns (Version memory) {
        return Version(uint64(_version >> 192), uint64(_version >> 128), uint128(_version));
    }

    function toString(Version memory _version) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    Strings.toString(uint256(_version.major)),
                    ".",
                    Strings.toString(uint256(_version.minor)),
                    ".",
                    Strings.toString(uint256(_version.patch))
                )
            );
    }

    function require_exact(Version memory _version1, Version memory _version2) internal pure {
        if (toUint256(_version1) != toUint256(_version2)) revert versionMissmatch("Version mismatch");
    }

    function require_major(Version memory _version1, Version memory _version2) internal pure {
        if (_version1.major != _version2.major) revert versionMissmatch("Major version mismatch");
    }

    function require_major_minor(Version memory _version1, Version memory _version2) internal pure {
        if (_version1.major != _version2.major || _version1.minor != _version2.minor)
            revert versionMissmatch("Major and minor version mismatch");
    }

    function require_greater_equal(Version memory _version1, Version memory _version2) internal pure {
        if (toUint256(_version1) < toUint256(_version2)) revert versionMissmatch("Version is not greater or equal");
    }

    function require_greater(Version memory _version1, Version memory _version2) internal pure {
        if (toUint256(_version1) <= toUint256(_version2)) revert versionMissmatch("Version is not greater");
    }

    function require_lesser_equal(Version memory _version1, Version memory _version2) internal pure {
        if (toUint256(_version1) > toUint256(_version2)) revert versionMissmatch("Version is not lesser or equal");
    }

    function require_lesser(Version memory _version1, Version memory _version2) internal pure {
        if (toUint256(_version1) >= toUint256(_version2)) revert versionMissmatch("Version is not lesser");
    }

    function compare(Version memory _version1, Version memory _version2) internal pure returns (uint256) {
        return toUint256(_version1) - toUint256(_version2);
    }

    function compare(
        Version memory _version1,
        Version memory _version2,
        requirements _requirement
    ) internal pure returns (bool) {
        if (_requirement == requirements.ANY) return true;
        if (_requirement == requirements.EXACT) return toUint256(_version1) == toUint256(_version2);
        if (_requirement == requirements.MAJOR) return _version1.major == _version2.major;
        if (_requirement == requirements.MAJOR_MINOR)
            return _version1.major == _version2.major && _version1.minor == _version2.minor;
        if (_requirement == requirements.GREATER_EQUAL) return toUint256(_version1) >= toUint256(_version2);
        if (_requirement == requirements.GREATER) return toUint256(_version1) > toUint256(_version2);
        if (_requirement == requirements.LESSER_EQUAL) return toUint256(_version1) <= toUint256(_version2);
        if (_requirement == requirements.LESSER) return toUint256(_version1) < toUint256(_version2);
        return false;
    }

    function getNextMajor(Version memory _version) internal pure returns (Version memory) {
        return Version(_version.major + 1, 0, 0);
    }

    function getNextMinor(Version memory _version) internal pure returns (Version memory) {
        return Version(_version.major, _version.minor + 1, 0);
    }

    function getNextPatch(Version memory _version) internal pure returns (Version memory) {
        return Version(_version.major, _version.minor, _version.patch + 1);
    }
}
