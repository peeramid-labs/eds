// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
import "../interfaces/IDistributor.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IInstaller.sol";

abstract contract Installer is IInstaller {
    using EnumerableSet for EnumerableSet.AddressSet;
    address private immutable _target;
    EnumerableSet.AddressSet private _distributors;
    mapping(address => address) private _instancesDistributor;
    mapping(uint256 => address[]) private _instanceEnum;
    uint256 instancesNum;

    constructor(address targetAddress) {
        _target = targetAddress;
    }

    function _addDistributor(IDistributor distributor) internal {
        _distributors.add(address(distributor));
    }

    function _removeDistributor(IDistributor distributor) internal {
        _distributors.remove(address(distributor));
    }

    function isDistributor(IDistributor distributor) public view returns (bool) {
        return _distributors.contains(address(distributor));
    }

    function getDistributors() public view returns (address[] memory) {
        return _distributors.values();
    }

    function _install(
        IDistributor distributor,
        bytes32 distributionId,
        bytes calldata args
    ) internal virtual returns (uint256 instanceId) {
        if (!isDistributor(distributor)) {
            revert InvalidDistributor(distributor);
        }
        (address[] memory installation,,) = distributor.instantiate(distributionId, args);
        instancesNum++;
        _instanceEnum[instancesNum] = installation;
        for (uint i = 0; i < installation.length; i++) {
            _instancesDistributor[installation[i]] = address(distributor);
            emit Installed(installation[0], distributionId, "0x", args);
        }
        return instancesNum;
    }

    function _uninstall(uint256 instanceId) internal virtual {
        address[] memory instance = _instanceEnum[instanceId];
        for (uint i = 0; i < instance.length; i++) {
            _instancesDistributor[instance[i]] = address(0);
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
        return _instancesDistributor[instance] != address(0);
    }

    function distributorOf(address instance) public view returns (IDistributor) {
        return IDistributor(_instancesDistributor[instance]);
    }

    function target() public view returns (address) {
        return _target;
    }

    function beforeCall(
        bytes memory layerConfig,
        bytes4 selector,
        address sender,
        uint256 value,
        bytes memory data
    ) public returns (bytes memory) {
        if (msg.sender != _target) {
            revert InvalidTarget(msg.sender);
        }
        address distributor = _instancesDistributor[sender];
        if (distributor != address(0)) {
            return IDistributor(distributor).beforeCall(layerConfig, selector, sender, value, data);
        }
        revert NotAnInstance(sender);
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
        address distributor = _instancesDistributor[sender];
        if (distributor != address(0)) {
            IDistributor(distributor).afterCall(layerConfig, selector, sender, value, data, beforeCallResult);
            return;
        }
        revert NotAnInstance(sender);
    }
}
