// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../distributions/LatestVersionDistribution.sol";
import "../interfaces/IDistribution.sol";

contract MockLatestVersionDistribution is LatestVersionDistribution {
    bytes32 private immutable _metadata;

    constructor(address repository_, bytes32 metadata_) LatestVersionDistribution(IRepository(repository_), metadata_) {
        _metadata = metadata_;
    }

    function contractURI() external view override returns (string memory) {
        // Convert the bytes32 to a string
        return bytes32ToString(_metadata);
    }

    function sources() internal view override returns (address[] memory srcs, bytes32 name, uint256 version) {
        return super.sources();
    }

    function instantiate(bytes memory) external override returns (address[] memory instances, bytes32 name, uint256 version) {
        return super._instantiate();
    }

    // Helper function to convert bytes32 to string
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}