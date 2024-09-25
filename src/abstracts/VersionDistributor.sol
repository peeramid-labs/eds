// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "../interfaces/IDistribution.sol";
import "../interfaces/IDistributor.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IInitializer.sol";
import "../abstracts/CodeIndexer.sol";
import "./Distributor.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../interfaces/IVersionDistributor.sol";
abstract contract VersionDistributor is IVersionDistributor, CodeIndexer {
    using LibSemver for LibSemver.Version;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _repositories;
    mapping(address => IInitializer) private initializers;
    mapping(address => address) private distributionOf;
    mapping(address => LibSemver.Version) private versions;
    mapping(address => LibSemver.requirements) private requirements;
    mapping(address => LibSemver.Version) private instancesVersions;

    function _addVersionedDistribution(
        IRepository repository,
        LibSemver.Version memory version,
        LibSemver.requirements requirement,
        address initializer
    ) internal {
        if (!ERC165Checker.supportsInterface(address(repository), type(IRepository).interfaceId)) {
            revert InvalidRepository(repository);
        }
        initializers[address(repository)] = IInitializer(initializer);
        _repositories.add(address(repository));
        versions[address(repository)] = version;
        requirements[address(repository)] = requirement;
        emit VersionedDistributionAdded(repository, LibSemver.toUint256(version), requirement, initializer);
    }

    function _changeRequirement(
        IRepository repository,
        LibSemver.Version memory version,
        LibSemver.requirements requirement
    ) internal {
        uint256 oldVersion = LibSemver.toUint256(versions[address(repository)]);
        uint256 newVersion = LibSemver.toUint256(version);
        LibSemver.requirements oldRequirement = requirements[address(repository)];
        versions[address(repository)] = version;
        requirements[address(repository)] = requirement;
        if (oldVersion != newVersion)
            emit VersionChanged(address(repository), oldVersion, LibSemver.toUint256(version));
        if (oldRequirement != requirement) emit RequirementChanged(repository, oldRequirement, requirement);
    }

    function _instantiate(
        IRepository repository,
        bytes calldata args
    ) internal returns (address[] memory, bytes32, uint256) {
        if (!_repositories.contains(address(repository))) {
            revert InvalidRepository(repository);
        }
        IRepository.Source memory src = repository.get(
            versions[address(repository)],
            requirements[address(repository)]
        );

        (address[] memory instances, bytes32 _distributionName, uint256 _distributionVersion) = IDistribution(
            getContractsIndex().get(src.sourceId)
        ).instantiate("");
        bytes4 selector = IInitializer.initialize.selector;

        address initializer = address(initializers[address(repository)]);
        if (initializer != address(0)) {
            (bool success, bytes memory result) = initializer.delegatecall(
                abi.encodeWithSelector(selector, instances, args)
            );
            require(success, string(result));
        }

        for (uint256 i = 0; i < instances.length; i++) {
            distributionOf[instances[i]] = address(repository);
            instancesVersions[instances[i]] = src.version;
        }
        emit Instantiated(address(repository), args);
        return (instances, _distributionName, _distributionVersion);
    }

    function getVersionedDistributions() public view returns (address[] memory repositories) {
        return _repositories.values();
    }

    function getVersionedDistributionURI(IRepository repository) public view returns (string memory) {
        return
            IDistribution(
                getContractsIndex().get(
                    repository.get(versions[address(repository)], requirements[address(repository)]).sourceId
                )
            ).getMetadata();
    }

    function _removeVersionedDistribution(IRepository repository) internal {
        if (!_repositories.contains(address(repository))) {
            revert InvalidRepository(repository);
        }
        _repositories.remove(address(repository));
        emit VersionedDistributionRemoved(repository);
    }

    function beforeCall(
        bytes memory,
        bytes4,
        address instance,
        uint256,
        bytes memory
    ) public view returns (bytes memory) {
        address repo = distributionOf[instance];
        if (repo != address(0) && _repositories.contains(repo)) {
            LibSemver.Version memory version = instancesVersions[instance];
            if (!version.compare(versions[repo], requirements[repo])) {
                revert VersionOutdated(IRepository(repo), LibSemver.toUint256(version));
            }
            return "";
        } else {
            revert InvalidInstance(instance);
        }
    }

    function afterCall(
        bytes memory layerConfig,
        bytes4 selector,
        address sender,
        uint256 value,
        bytes memory data,
        bytes memory beforeCallResult
    ) public {}
}
