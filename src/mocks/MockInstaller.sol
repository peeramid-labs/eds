// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../middleware/InstallerClonable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract MockInstaller is InstallerClonable, Ownable {
    constructor(address targetAddress, address owner) Ownable(owner) InstallerClonable(true) {
        initialize(targetAddress);
    }

    function install(
        IDistributor distributor,
        bytes32 distributionId,
        bytes calldata args
    ) public payable returns (uint256 instanceId) {
        return super._install(distributor, distributionId, args);
    }

    function uninstall(uint256 instanceId) public onlyOwner {
        super._uninstall(instanceId);
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
    _changeDistributor(appId, newDistributor, appData);
   }

   function upgradeApp(uint256 appId, bytes32 migrationId, bytes calldata userCalldata) public onlyOwner {
    _upgradeApp(appId, migrationId, userCalldata);
   }
}
