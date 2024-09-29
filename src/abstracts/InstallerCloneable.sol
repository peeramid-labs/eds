// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "../interfaces/IDistributor.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IInstaller.sol";
import "../libraries/LibInstaller.sol";
abstract contract InstallerClonable is IInstaller, Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    constructor() {
        _disableInitializers();
    }

    function initialize(address targetAddress) public virtual initializer {
        LibInstaller.getStorage()._target = targetAddress;
    }

    function isDistributor(IDistributor distributor) public view returns (bool) {
        return LibInstaller.getStorage().whitelistedDistributors.contains(address(distributor));
    }

    function getWhitelistedDistributors() public view returns (address[] memory) {
        return LibInstaller.getStorage().whitelistedDistributors.values();
    }

    function whitelistedDistributions(IDistributor distributor) public view returns (bytes32[] memory) {
        if (LibInstaller.getStorage().whitelistedDistributors.contains(address(distributor))) {
            return distributor.getDistributions();
        } else {
            return LibInstaller.getStorage()._permittedDistributions[address(distributor)].values();
        }
    }

    function _allowAllDistributions(IDistributor distributor) internal virtual {
        LibInstaller.getStorage().whitelistedDistributors.add(address(distributor));
    }

    function _disallowAllDistributions(IDistributor distributor) internal virtual {
        LibInstaller.getStorage().whitelistedDistributors.remove(address(distributor));
    }

    function _allowDistribution(IDistributor distributor, bytes32 distributionId) internal virtual {
        if (LibInstaller.getStorage().whitelistedDistributors.contains(address(distributor))) {
            revert alreadyAllowed(distributor);
        }
        LibInstaller.getStorage()._permittedDistributions[address(distributor)].add(distributionId);
    }

    function _disallowDistribution(IDistributor distributor, bytes32 distributionId) internal virtual {
        if (LibInstaller.getStorage().whitelistedDistributors.contains(address(distributor))) {
            revert DissalowDistOnWhitelistedDistributor(distributor, distributionId);
        }
        LibInstaller.getStorage()._permittedDistributions[address(distributor)].remove(distributionId);
    }

    function enforceActiveDistribution(IDistributor distributor, bytes32 distributionId) internal view {
        LibInstaller.InstallerStruct storage strg = LibInstaller.getStorage();
        if (
            !strg.whitelistedDistributors.contains(address(distributor)) &&
            !strg._permittedDistributions[address(distributor)].contains(distributionId)
        ) {
            revert DistributionIsNotPermitted(distributor, distributionId);
        }
    }

    function _install(
        IDistributor distributor,
        bytes32 distributionId,
        bytes calldata args
    ) internal virtual returns (uint256 instanceId) {
        LibInstaller.InstallerStruct storage strg = LibInstaller.getStorage();
        if (
            !isDistributor(distributor) && !strg._permittedDistributions[address(distributor)].contains(distributionId)
        ) {
            revert InvalidDistributor(distributor);
        }
        enforceActiveDistribution(distributor, distributionId);
        (address[] memory installation, , ) = distributor.instantiate(distributionId, args);
        strg.instancesNum++;
        strg._instanceEnum[strg.instancesNum] = installation;
        uint256 installationlength = installation.length;
        for (uint256 i = 0; i < installationlength; ++i) {
            strg._distributorOf[installation[i]] = address(distributor);
            emit Installed(installation[0], distributionId, "0x", args);
        }
        return strg.instancesNum;
    }

    function _uninstall(uint256 instanceId) internal virtual {
        LibInstaller.InstallerStruct storage strg = LibInstaller.getStorage();
        address[] memory instance = strg._instanceEnum[instanceId];
        uint256 length = instance.length;
        for (uint256 i = 0; i < length; ++i) {
            strg._distributorOf[instance[i]] = address(0);
            emit Uninstalled(instance[i]);
        }
        strg.instancesNum--;
    }

    function getInstance(uint256 instanceId) public view returns (address[] memory instaneContracts) {
        return LibInstaller.getStorage()._instanceEnum[instanceId];
    }

    function getInstancesNum() public view returns (uint256) {
        return LibInstaller.getStorage().instancesNum;
    }

    function isInstance(address instance) public view returns (bool) {
        return LibInstaller.getStorage()._distributorOf[instance] != address(0);
    }

    function distributorOf(address instance) public view returns (IDistributor) {
        return IDistributor(LibInstaller.getStorage()._distributorOf[instance]);
    }

    function target() public view returns (address) {
        return LibInstaller.getStorage()._target;
    }

    function beforeCall(
        bytes memory layerConfig,
        bytes4 selector,
        address requestingInstance,
        uint256 value,
        bytes memory data
    ) external virtual returns (bytes memory) {
        LibInstaller.InstallerStruct storage installerSettings = LibInstaller.getStorage();
        if (msg.sender != installerSettings._target) {
            revert InvalidTarget(msg.sender);
        }
        address distributor = installerSettings._distributorOf[requestingInstance];
        if (distributor != address(0)) {
            bytes memory beforeCallValue = IDistributor(distributor).beforeCall(
                layerConfig,
                selector,
                requestingInstance,
                value,
                data
            );
            (bytes32 id, ) = abi.decode(beforeCallValue, (bytes32, bytes));
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
    ) external virtual {
        LibInstaller.InstallerStruct storage installerSettings = LibInstaller.getStorage();
        if (msg.sender != installerSettings._target) {
            revert InvalidTarget(msg.sender);
        }
        address distributor = LibInstaller.getStorage()._distributorOf[sender];
        if (distributor != address(0)) {
            IDistributor(distributor).afterCall(layerConfig, selector, sender, value, data, beforeCallResult);
        }
        revert NotAnInstance(sender);
    }
}
