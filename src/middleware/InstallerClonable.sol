// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "../interfaces/IDistributor.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IInstaller.sol";
import "../versioning/LibSemver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
/**
 * @title Installer
 * @notice Abstract contract that implements the IInstaller interface and is Initializable.
 * This contract serves as a base for creating clonable installer contracts.
 */
abstract contract InstallerClonable is IInstaller, Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct InstallerStruct {
        address _target;
        EnumerableSet.AddressSet whitelistedDistributors;
        mapping(address => EnumerableSet.Bytes32Set) _permittedDistributions;
        mapping(address appElement => uint256 appId) appIds;
        uint256 appNum;
        mapping(uint256 appId => App app) apps;
        LibSemver.Version currentVersion;
    }

    bytes32 private constant EDS_INSTALLER_STORAGE_POSITION = keccak256("EDS.INSTALLER.STORAGE.POSITION");

    function getStorage() internal pure returns (InstallerStruct storage i) {
        bytes32 position = EDS_INSTALLER_STORAGE_POSITION;
        assembly {
            i.slot := position
        }
    }

    using EnumerableSet for EnumerableSet.AddressSet;
    using LibSemver for LibSemver.Version;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    constructor(bool isTest) {
        if (!isTest) {
            _disableInitializers();
        }
    }
    // @inheritdoc IInstaller
    function initialize(address targetAddress) public virtual initializer {
        getStorage()._target = targetAddress;
    }
    // @inheritdoc IInstaller
    function isDistributor(IDistributor distributor) public view returns (bool) {
        return getStorage().whitelistedDistributors.contains(address(distributor));
    }
    // @inheritdoc IInstaller
    function getWhitelistedDistributors() public view returns (address[] memory) {
        return getStorage().whitelistedDistributors.values();
    }
    // @inheritdoc IInstaller
    function whitelistedDistributions(IDistributor distributor) public view returns (bytes32[] memory) {
        if (getStorage().whitelistedDistributors.contains(address(distributor))) {
            return distributor.getDistributions();
        } else {
            return getStorage()._permittedDistributions[address(distributor)].values();
        }
    }

    function _allowAllDistributions(IDistributor distributor) internal virtual {
        getStorage().whitelistedDistributors.add(address(distributor));
    }

    function _disallowAllDistributions(IDistributor distributor) internal virtual {
        getStorage().whitelistedDistributors.remove(address(distributor));
    }

    function _allowDistribution(IDistributor distributor, bytes32 distributionId) internal virtual {
        if (getStorage().whitelistedDistributors.contains(address(distributor))) {
            revert alreadyAllowed(distributor);
        }
        getStorage()._permittedDistributions[address(distributor)].add(distributionId);
    }

    function _disallowDistribution(IDistributor distributor, bytes32 distributionId) internal virtual {
        if (getStorage().whitelistedDistributors.contains(address(distributor))) {
            revert DisallowDistOnWhitelistedDistributor(distributor, distributionId);
        }
        getStorage()._permittedDistributions[address(distributor)].remove(distributionId);
    }

    function enforceActiveDistribution(IDistributor distributor, bytes32 distributionId) internal view {
        InstallerStruct storage strg = getStorage();
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
    ) internal virtual returns (uint256 appId) {
        InstallerStruct storage strg = getStorage();
        if (
            !isDistributor(distributor) && !strg._permittedDistributions[address(distributor)].contains(distributionId)
        ) {
            revert InvalidDistributor(distributor);
        }
        enforceActiveDistribution(distributor, distributionId);
        (address[] memory installation, , ) = distributor.instantiate(distributionId, args);
        strg.appNum++;
        strg.apps[strg.appNum] = App(installation, address(distributor), args);
        uint256 installationLength = installation.length;
        for (uint256 i; i < installationLength; ++i) {
            strg.appIds[installation[i]] = strg.appNum;
            emit Installed(installation[0], distributionId, "0x", args);
        }
        return strg.appNum;
    }

    function _uninstall(uint256 appId) internal virtual {
        InstallerStruct storage strg = getStorage();
        App memory app = strg.apps[appId];
        uint256 length = app.contracts.length;
        for (uint256 i; i < length; ++i) {
            strg.appIds[app.contracts[i]] = 0;
            emit Uninstalled(app.contracts[i]);
        }
        strg.appNum--;
    }
    // @inheritdoc IInstaller
    function getApp(uint256 appId) public view returns (App memory app) {
        InstallerStruct storage strg = getStorage();
        return strg.apps[appId];
    }
    // @inheritdoc IInstaller
    function getAppsNum() public view returns (uint256) {
        InstallerStruct storage strg = getStorage();
        return strg.appNum;
    }
    // @inheritdoc IInstaller
    function isApp(address appComponent) public view returns (bool) {
        InstallerStruct storage strg = getStorage();
        return strg.appIds[appComponent] != 0;
    }
    // @inheritdoc IInstaller
    function distributorOf(address appComponent) public view returns (IDistributor) {
        InstallerStruct storage strg = getStorage();
        return IDistributor(strg.apps[strg.appIds[appComponent]].middleware);
    }
    // @inheritdoc IInstaller
    function target() public view returns (address) {
        return getStorage()._target;
    }
    // @inheritdoc IERC7746
    // @notice two call directions are supported: anyone -> app; app -> installation target
    // @dev it will daisy-chain the call to the distributor, if app is valid and active distribution
    function beforeCall(
        bytes memory layerConfig,
        bytes4 selector,
        address origin,
        uint256 value,
        bytes memory data
    ) external virtual returns (bytes memory) {
        InstallerStruct storage strg = getStorage();
        bool isTarget = msg.sender == strg._target;
        address app = isTarget ? origin : msg.sender;
        uint256 appId = strg.appIds[app];
        address distributor = strg.apps[appId].middleware;
        if (!isTarget && appId == 0) {
            // if the sender is not the target and is not an installed app, revert
            revert InvalidTarget(msg.sender);
        }
        if (distributor != address(0)) {
            bytes memory beforeCallValue = IDistributor(distributor).beforeCall(
                layerConfig,
                selector,
                app,
                value,
                data
            );
            (bytes32 id, ) = abi.decode(beforeCallValue, (bytes32, bytes));
            enforceActiveDistribution(IDistributor(distributor), id);
            return abi.encode(id, distributor);
        } else {
            // If the sender is target, allow only calls originating from installed apps
            if (isTarget) revert NotAnApp(origin);
        }
        //return 0xFF code: no distributor to the target
        return abi.encode(0xFF, distributor);
    }
    // @inheritdoc IERC7746
    // @notice this will revert if the sender is not the target or requesting app is not a valid app
    // @dev it will daisy-chain the call to the distributor, if app is valid and active distribution
    function afterCall(
        bytes memory layerConfig,
        bytes4 selector,
        address origin,
        uint256 value,
        bytes memory data,
        bytes memory beforeCallResult
    ) external virtual {
        InstallerStruct storage strg = getStorage();
        bool isTarget = msg.sender == strg._target;
        address app = isTarget ? origin : msg.sender;
        uint256 appId = strg.appIds[app];
        address distributor = strg.apps[appId].middleware;
        if (!isTarget && appId == 0) {
            revert InvalidTarget(msg.sender);
        }
        if (distributor != address(0)) {
            IDistributor(distributor).afterCall(layerConfig, selector, origin, value, data, beforeCallResult);
        }
    }

    function _upgradeApp(uint256 appId, bytes32 migrationId, bytes calldata userCalldata) internal virtual {
        InstallerStruct storage strg = getStorage();
        App memory app = strg.apps[appId];
        require(app.middleware != address(0), "App not installed");
        IDistributor distributor = IDistributor(app.middleware);
        uint256 distributorAppId = distributor.getAppId(app.contracts[0]);
        LibSemver.Version memory newVersion = distributor.upgradeUserInstance(
            distributorAppId,
            migrationId,
            userCalldata
        );
        emit AppUpgraded(appId, migrationId, newVersion.toUint256(), userCalldata);
    }

    function _changeDistributor(
        uint256 appId,
        IDistributor newDistributor,
        bytes[] memory appData
    ) internal virtual returns (bool[] memory statuses, bytes[] memory results) {
        InstallerStruct storage strg = getStorage();
        IDistributor oldDistributor = IDistributor(strg.apps[appId].middleware);
        uint256 oldDistributorAppId = oldDistributor.getAppId(strg.apps[appId].contracts[0]);
        require(
            ERC165Checker.supportsInterface(address(newDistributor), type(IDistributor).interfaceId),
            "New distributor does not support IDistributor"
        );
        strg.apps[appId].middleware = address(newDistributor);
        emit DistributorChanged(appId, newDistributor);
        require(appData.length == strg.apps[appId].contracts.length || appData.length == 0, "App data length mismatch");
        return oldDistributor.onDistributorChanged(oldDistributorAppId, address(newDistributor), appData);
    }
}
