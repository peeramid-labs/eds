// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "../abstracts/Installer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract MockInstaller is Installer, Ownable {
    constructor(address targetAddress, address owner) Ownable(owner) Installer(targetAddress) {}
    function addDistributor(IDistributor distributor) public onlyOwner {
        super._addDistributor(distributor);
    }

    function removeDistributor(IDistributor distributor) public onlyOwner {
        super._removeDistributor(distributor);
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


    function allowAllDistributions(IDistributor distributor) public onlyOwner {
        super._allowAllDistributions(distributor);
    }

    function disallowAllDistributions(IDistributor distributor) public onlyOwner {
        super._disallowAllDistributions(distributor);
    }
}
