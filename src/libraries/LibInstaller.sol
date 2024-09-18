// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibInstaller {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct InstallerStruct {
        address _target;
        EnumerableSet.AddressSet whitelistedDistributors;
        mapping(address => EnumerableSet.Bytes32Set) _permittedDistributions;
        mapping(address => address) _distributorOf;
        mapping(uint256 => address[]) _instanceEnum;
        uint256 instancesNum;
    }

    bytes32 constant EDS_INSTALLER_STORAGE_POSITION = keccak256("EDS.INSTALLER.STORAGE.POSITION");

    function getStorage() internal pure returns (InstallerStruct storage i) {
        bytes32 position = EDS_INSTALLER_STORAGE_POSITION;
        assembly {
            i.slot := position
        }
    }
}
