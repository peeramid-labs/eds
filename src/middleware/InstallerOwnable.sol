// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./InstallerClonable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
contract OwnableInstaller is InstallerClonable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    constructor(address target, address owner) Ownable(owner) InstallerClonable() {
        initialize(target, owner);
    }

    function initialize(address targetAddress, address owner) public initializer {
        super.initialize(targetAddress);
        _transferOwnership(owner);
    }

    function install(
        IDistributor distributor,
        bytes32 distributionId,
        bytes calldata args
    ) public payable returns (uint256 instanceId) {
        InstallerStruct storage strg = getStorage();
        // We do this check first as implementation specific, making installs by owner removable by default once distributor/n is removed
        if (isDistributor(distributor) || strg._permittedDistributions[address(distributor)].contains(distributionId)) {
            return _installPublic(distributor, distributionId, args);
        } else if (msg.sender == owner()) {
            return _installByOwner(distributor, distributionId, args);
        }
        return _installPublic(distributor, distributionId, args); // This should revert since check above has failed
    }

    function uninstall(uint256 appId) public onlyOwner {
        super._uninstall(appId);
    }

    function allowDistribution(IDistributor distributor, bytes32 distributionId) public onlyOwner {
        super._allowDistribution(distributor, distributionId);
    }

    function disallowDistribution(IDistributor distributor, bytes32 distributionId) public onlyOwner {
        super._disallowDistribution(distributor, distributionId);
    }

    function whitelistDistributor(IDistributor distributor) public onlyOwner {
        super._allowAllDistributions(distributor);
    }

    function revokeWhitelistedDistributor(IDistributor distributor) public onlyOwner {
        super._disallowAllDistributions(distributor);
    }

    function changeDistributor(uint256 appId, IDistributor newDistributor, bytes[] memory appData) public onlyOwner {
        super._changeDistributor(appId, newDistributor, appData);
    }

    function upgradeApp(uint256 appId, bytes32 migrationId, bytes calldata userCalldata) public onlyOwner {
        super._upgradeApp(appId, migrationId, userCalldata);
    }
}
