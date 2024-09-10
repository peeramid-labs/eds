// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IDistribution.sol";
import "./CodeIndexer.sol";

abstract contract CloneDistribution is IDistribution, CodeIndexer {


    function sources() internal view virtual returns (address[] memory, bytes32 name, uint256 version);

    function instantiate() public virtual returns (address[] memory instances, bytes32 distributionName, uint256 distributionVersion) {
        (address[] memory _sources,bytes32 _distributionName,uint256 _distributionVersion) = sources();
        instances = new address[](_sources.length);
        for (uint256 i = 0; i < _sources.length; i++) {
            address clone = Clones.clone(_sources[i]);
            instances[i] = clone;
        }
        emit Distributed(msg.sender, instances);
        return (instances, _distributionName, _distributionVersion);
    }

    function get() public view virtual returns (address[] memory src, bytes32 name, uint256 version) {
        return sources();
    }

    function getMetadata() public view virtual returns (string memory);
}
