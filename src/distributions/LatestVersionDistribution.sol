// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "../abstracts/CloneDistribution.sol";
import "../interfaces/IRepository.sol";
import "../libraries/LibSemver.sol";

contract LatestVersionDistribution is CloneDistribution {
    bytes32 immutable metadata;
    IRepository immutable repository;

    constructor(IRepository _repository, bytes32 _metadata) {
        metadata = _metadata;
        repository = _repository;
    }

    function sources() internal view virtual override returns (address[] memory srcs, bytes32 name, uint256 version) {
        address[] memory _sources = new address[](1);
        IRepository.Source memory latest = repository.getLatest();
        _sources[0] = getContractsIndex().get(latest.sourceId);
        return (_sources, repository.repositoryName(),LibSemver.toUint256(latest.version));
    }

    function getMetadata() public view virtual override returns (string memory) {
        return string(abi.encodePacked(metadata)); //ToDo: Add IPFS link with readme!
    }
}
