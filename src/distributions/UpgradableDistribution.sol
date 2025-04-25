// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IDistribution.sol";
import "../erc7744/LibERC7744.sol";
import {WrappedTransparentUpgradeableProxy} from "../proxies/WrappedTransparentUpgradeableProxy.sol";
// import "./LibMiddleware.sol";
abstract contract UpgradableDistribution is IDistribution {
    error CodeNotFoundInIndex(bytes32 codeId);

    function sources() internal view virtual returns (address[] memory, bytes32 name, uint256 version);

    // @inheritdoc IDistribution
    function _instantiate(address installer, bytes memory data)
        internal
        virtual
        returns (address[] memory instances, bytes32 distributionName, uint256 distributionVersion)
    {
        (address[] memory _sources, bytes32 _distributionName, uint256 _distributionVersion) = sources();
        uint256 srcsLength = _sources.length;
        instances = new address[](srcsLength);
        for (uint256 i; i < srcsLength; ++i) {
            address proxy = address(new WrappedTransparentUpgradeableProxy(_sources[i], installer, data, ""));
            instances[i] = proxy;
        }
        emit Distributed(msg.sender, instances);
        return (instances, _distributionName, _distributionVersion);
    }
    // @inheritdoc IDistribution
    function get() external view virtual returns (address[] memory src, bytes32 name, uint256 version) {
        return sources();
    }
    // @inheritdoc IDistribution
    function contractURI() external view virtual returns (string memory);
}
