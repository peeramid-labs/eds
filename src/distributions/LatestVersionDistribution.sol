// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../abstracts/CloneDistribution.sol";
import "../interfaces/IRepository.sol";
import "../libraries/LibSemver.sol";

/**
 * @title LatestVersionDistribution
 * @notice This contract extends the CloneDistribution contract to manage the distribution of the latest version of a given resource.
 * It provides mechanisms to ensure that the most recent version is distributed to users.
 * @dev it MUST refer to {../interfaces/IRepository}
 */
contract LatestVersionDistribution is CloneDistribution {
    bytes32 private immutable metadata;
    IRepository public immutable repository;

    /**
     * @notice Constructor for the LatestVersionDistribution contract.
     * @param _repository The address of the IRepository contract.
     * @param _metadata The metadata associated with the distribution.
     */
    constructor(IRepository _repository, bytes32 _metadata) {
        metadata = _metadata;
        repository = _repository;
    }

    function sources() internal view virtual override returns (address[] memory srcs, bytes32 name, uint256 version) {
        address[] memory _sources = new address[](1);
        IRepository.Source memory latest = repository.getLatest();
        _sources[0] = getContractsIndex().get(latest.sourceId);
        return (_sources, repository.repositoryName(), LibSemver.toUint256(latest.version));
    }

    function contractURI() external view virtual override returns (string memory) {
        return string(abi.encodePacked(metadata)); //ToDo: Add IPFS link with readme!
    }
}
