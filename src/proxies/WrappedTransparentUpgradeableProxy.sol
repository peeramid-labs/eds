pragma solidity ^0.8.28;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IERC7746} from "../interfaces/IERC7746.sol";
import "../middleware/ERC7746Hooked.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IDistributor} from "../interfaces/IDistributor.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

interface IAdminGetter {
    function getWrappedProxyAdmin() external view returns (address);
}

error InvalidMiddleware();

/**
 * @title AdminWrappedTransparentUpgradeableProxy
 * @notice This contract is a transparent upgradeable proxy that allows for immutable middleware hooks.
 * @custom:security-contact sirt@peeramid.xyz
 */
contract WrappedTransparentUpgradeableProxy is TransparentUpgradeableProxy, ERC7746Hooked {
    constructor(
        address _logic,
        address _admin,
        bytes memory _data,
        bytes memory _middlewareData
    ) TransparentUpgradeableProxy(_logic, msg.sender, _data) {
        LibMiddleware.LayerStruct[] memory layers = new LibMiddleware.LayerStruct[](1);
        layers[0] = LibMiddleware.LayerStruct({layerAddress: _admin, layerConfigData: _middlewareData});
        LibMiddleware.setLayers(layers);
    }

    function _fallback() internal virtual override ERC7746 {
        // Return the admin address if the call is to getAdmin and the caller is the owner of the proxy admin
        if (msg.sig == IAdminGetter.getWrappedProxyAdmin.selector && msg.sender == ProxyAdmin(_proxyAdmin()).owner()) {
            address proxyAdminAddress = _proxyAdmin();
            assembly {
                mstore(0x00, proxyAdminAddress)
                calldatacopy(0, 0, calldatasize())
                return(0x00, 0x20)
            }
        } else {
            super._fallback();
        }
    }
}
