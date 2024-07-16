// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./IDistribution.sol";
import "../layers/ILayer.sol";
import "../interfaces/IRepository.sol";
import "../libraries/LibSemver.sol";
interface IVersionDistributor is ILayer {
    error InvalidRepository(IRepository repository);
    error RepositoryAlreadyExists(IRepository repository);
    error VersionOutdated(IRepository repository, uint256 version);
    error InvalidInstance(address instance);
    event VersionedDistributionAdded(
        IRepository indexed repository,
        uint256 indexed version,
        LibSemver.requirements requirement,
        bytes32 indexed initializerId
    );
    event VersionChanged(address indexed repository, uint256 indexed oldVersion, uint256 indexed newVersion);
    event RequirementChanged(
        IRepository indexed repository,
        LibSemver.requirements indexed oldRequirement,
        LibSemver.requirements indexed newRequirement
    );
    event VersionedDistributionRemoved(IRepository indexed repository);
    event Instantiated(address indexed repository, bytes indexed argsHash);

    function addVersionedDistribution(
        IRepository repository,
        LibSemver.Version memory version,
        LibSemver.requirements requirement,
        bytes32 initializer
    ) external;

    function changeRequirement(
        IRepository repository,
        LibSemver.Version memory version,
        LibSemver.requirements requirement
    ) external;

    function getVersionedDistributions() external view returns (address[] memory repositories);
    function getVersionedDistributionURI(IRepository repository) external view returns (string memory);
    function instantiate(IRepository repository, bytes calldata args) external returns (address[] memory);
    function removeVersionedDistribution(IRepository repository) external;
}
