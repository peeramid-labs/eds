// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IDistribution.sol";
import "../erc7744/LibERC7744.sol";
import {WrappedTransparentUpgradeableProxy} from "../proxies/WrappedTransparentUpgradeableProxy.sol";
import {ShortString, ShortStrings} from "@openzeppelin/contracts/utils/ShortStrings.sol";
import {IAdminGetter} from "../interfaces/IAdminGetter.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

contract UpgradableDistribution is IDistribution {
    bytes32 private immutable metadata;
    address private immutable _reference;
    ShortString public immutable distributionName;
    uint256 public immutable distributionVersion;
    using LibERC7744 for bytes32;
    /**
     * @notice Constructor for the CodeHashDistribution contract.
     * @param codeHash The hash of the code to be distributed.
     * @param _metadata Metadata associated with the code.
     * @param name The name of the distribution.
     * @param version The version number of the distribution.
     */
    constructor(bytes32 codeHash, bytes32 _metadata, string memory name, uint256 version) {
        distributionName = ShortStrings.toShortString(name);
        distributionVersion = version;
        metadata = _metadata;
        _reference = codeHash.getContainerOrThrow();
    }

    // @inheritdoc IDistribution
    function sources() internal view virtual returns (address[] memory, bytes32 name, uint256 version) {
        address[] memory _sources = new address[](1);
        _sources[0] = _reference;
        return (_sources, ShortString.unwrap(distributionName), distributionVersion);
    }
    // @inheritdoc IDistribution
    function contractURI() external view virtual override returns (string memory) {
        return string(abi.encodePacked(metadata)); //ToDo: Add IPFS link with readme!
    }

    error CodeNotFoundInIndex(bytes32 codeId);

    // @inheritdoc IDistribution
    function instantiate(bytes memory data) public virtual returns (address[] memory instances, bytes32, uint256) {
        (address installer, bytes memory args) = abi.decode(data, (address, bytes));
        (address[] memory _sources, bytes32 _distributionName, uint256 _distributionVersion) = sources();
        uint256 srcsLength = _sources.length;
        instances = new address[](srcsLength);
        for (uint256 i; i < srcsLength; ++i) {
            address proxy = address(
                new WrappedTransparentUpgradeableProxy(_sources[i], installer, msg.sender, args, "")
            );
            instances[i] = proxy;
        }
        emit Distributed(msg.sender, instances);
        return (instances, _distributionName, _distributionVersion);
    }
    // @inheritdoc IDistribution
    function get() external view virtual returns (address[] memory src, bytes32 name, uint256 version) {
        return sources();
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IDistribution).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
