// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "../interfaces/IDistributor.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IInstaller.sol";
abstract contract Installer is IInstaller {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    address private immutable _target;
    EnumerableSet.AddressSet private whitelistedDistributors;
    mapping(address => EnumerableSet.Bytes32Set) private _permittedDistributions;
    mapping(address => address) private _distributorOf;
    mapping(uint256 => address[]) private _instanceEnum;
    uint256 instancesNum;

    constructor(address targetAddress) {
        _target = targetAddress;
    }

    function isDistributor(IDistributor distributor) public view returns (bool) {
        return whitelistedDistributors.contains(address(distributor));
    }

    function getWhitelistedDistributors() public view returns (address[] memory) {
        return whitelistedDistributors.values();
    }

    function whitelistedDistributions(IDistributor distributor) public view returns (bytes32[] memory) {
        if (whitelistedDistributors.contains(address(distributor))) {
            return distributor.getDistributions();
        } else {
            return _permittedDistributions[address(distributor)].values();
        }
    }

    function _allowAllDistributions(IDistributor distributor) internal virtual {
        whitelistedDistributors.add(address(distributor));
    }

    function _disallowAllDistributions(IDistributor distributor) internal virtual {
        whitelistedDistributors.remove(address(distributor));
    }

    function _allowDistribution(IDistributor distributor, bytes32 distributionId) internal virtual {
        if (whitelistedDistributors.contains(address(distributor))) {
            revert alreadyAllowed(distributor);
        }
        _permittedDistributions[address(distributor)].add(distributionId);
    }

    function _disallowDistribution(IDistributor distributor, bytes32 distributionId) internal virtual {
        if (whitelistedDistributors.contains(address(distributor))) {
            revert("cannot dissalow distribution on whitelisted distributor");
        }
        _permittedDistributions[address(distributor)].remove(distributionId);
    }

    function enforceActiveDistribution(IDistributor distributor, bytes32 distributionId) internal view {
        if (
            !whitelistedDistributors.contains(address(distributor)) &&
            !_permittedDistributions[address(distributor)].contains(distributionId)
        ) {
            revert DistributionIsNotPermitted(distributor, distributionId);
        }
    }

    function _install(
        IDistributor distributor,
        bytes32 distributionId,
        bytes calldata args
    ) internal virtual returns (uint256 instanceId) {
        if (!isDistributor(distributor) && !_permittedDistributions[address(distributor)].contains(distributionId)) {
            revert InvalidDistributor(distributor);
        }
        enforceActiveDistribution(distributor, distributionId);
        (address[] memory installation, , ) = distributor.instantiate(distributionId, args);
        instancesNum++;
        _instanceEnum[instancesNum] = installation;
        for (uint i = 0; i < installation.length; i++) {
            _distributorOf[installation[i]] = address(distributor);
            emit Installed(installation[0], distributionId, "0x", args);
        }
        return instancesNum;
    }

    function _uninstall(uint256 instanceId) internal virtual {
        address[] memory instance = _instanceEnum[instanceId];
        for (uint i = 0; i < instance.length; i++) {
            _distributorOf[instance[i]] = address(0);
            emit Uninstalled(instance[i]);
        }
        instancesNum--;
    }

    function getInstance(uint256 instanceId) public view returns (address[] memory instaneContracts) {
        return _instanceEnum[instanceId];
    }

    function getInstancesNum() public view returns (uint256) {
        return instancesNum;
    }

    function isInstance(address instance) public view returns (bool) {
        return _distributorOf[instance] != address(0);
    }

    function distributorOf(address instance) public view returns (IDistributor) {
        return IDistributor(_distributorOf[instance]);
    }

    function target() public view returns (address) {
        return _target;
    }

    function beforeCall(
        bytes memory layerConfig,
        bytes4 selector,
        address requestingInstance,
        uint256 value,
        bytes memory data
    ) public returns (bytes memory) {
        if (msg.sender != _target) {
            revert InvalidTarget(msg.sender);
        }
        address distributor = _distributorOf[requestingInstance];
        if (distributor != address(0)) {
            bytes memory beforeCallValue = IDistributor(distributor).beforeCall(layerConfig, selector, requestingInstance, value, data);
            (bytes32 id, )= abi.decode(beforeCallValue, (bytes32, bytes));
            enforceActiveDistribution(IDistributor(distributor), id);
            return abi.encode(id, distributor);
        }
        revert NotAnInstance(requestingInstance);
    }

    function afterCall(
        bytes memory layerConfig,
        bytes4 selector,
        address sender,
        uint256 value,
        bytes memory data,
        bytes memory beforeCallResult
    ) public {
        if (msg.sender != _target) {
            revert InvalidTarget(msg.sender);
        }
        address distributor = _distributorOf[sender];
        if (distributor != address(0)) {
            IDistributor(distributor).afterCall(layerConfig, selector, sender, value, data, beforeCallResult);
        }
        revert NotAnInstance(sender);
    }
}
