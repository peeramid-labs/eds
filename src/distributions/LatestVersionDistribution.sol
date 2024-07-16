// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../abstracts/CloneDistribution.sol";
import "../interfaces/IRepository.sol";

contract LatestVersionDistribution is CloneDistribution {
    bytes32 immutable metadata;
    IRepository immutable repository;

    constructor(IRepository _repository, bytes32 _metadata) {
        metadata = _metadata;
        repository = _repository;
    }

    function sources() internal view virtual override returns (address[] memory) {
        address[] memory _sources = new address[](1);

        _sources[0] = getContractsIndex().get(repository.getLatest().sourceId);
        return _sources;
    }

    function getMetadata() public view virtual override returns (string memory) {
        return string(abi.encodePacked(metadata)); //ToDo: Add IPFS link with readme!
    }
}
