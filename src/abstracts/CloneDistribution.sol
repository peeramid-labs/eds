// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IDistribution.sol";
import "./CodeIndexer.sol";

abstract contract CloneDistribution is IDistribution, CodeIndexer {
    function sources() internal view virtual returns (address[] memory);

    function instantiate() public virtual returns (address[] memory instances) {
        address[] memory _sources = sources();
        instances = new address[](_sources.length);
        for (uint256 i = 0; i < _sources.length; i++) {
            address clone = Clones.clone(_sources[i]);
            instances[i] = clone;
        }
        emit Distributed(msg.sender, instances);
        return instances;
    }

    function getSources() public view virtual returns (address[] memory) {
        return sources();
    }

    function getMetadata() public view virtual returns (string memory);
}
