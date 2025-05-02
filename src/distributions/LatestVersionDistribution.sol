// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./CloneDistribution.sol";
import "../interfaces/IRepository.sol";
import "../versioning/LibSemver.sol";
import "../erc7744/LibERC7744.sol";
import {ShortString, ShortStrings} from "@openzeppelin/contracts/utils/ShortStrings.sol";
/**
 * @title LatestVersionDistribution
 * @notice This contract extends the CloneDistribution contract to manage the distribution of the latest version of a given resource.
 * It provides mechanisms to ensure that the most recent version is distributed to users.
 * @dev it MUST refer to {../interfaces/IRepository}
 */
contract LatestVersionDistribution is CloneDistribution {
    ShortString private immutable metadata;
    IRepository public immutable repository;
    using LibERC7744 for bytes32;

    /**
     * @notice Constructor for the LatestVersionDistribution contract.
     * @param _repository The address of the IRepository contract.
     * @param _metadata The metadata associated with the distribution.
     */
    constructor(IRepository _repository, ShortString _metadata) {
        metadata = _metadata;
        repository = _repository;
    }

    /**
     * @inheritdoc IDistribution
     */
    function instantiate(bytes memory) external virtual returns (address[] memory instances, bytes32, uint256) {
        return super._instantiate();
    }

    function sources() internal view virtual override returns (address[] memory srcs, bytes32 name, uint256 version) {
        address[] memory _sources = new address[](1);
        IRepository.Source memory latest = repository.getLatest();
        _sources[0] = latest.sourceId.getContainerOrThrow();
        return (_sources, repository.repositoryName(), LibSemver.toUint256(latest.version));
    }

    /**
     * @inheritdoc IContractURI
     */
    function contractURI() external view virtual override returns (string memory) {
        return ShortStrings.toString(metadata);
    }
}
