// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./UpgradableDistribution.sol";
import {ShortStrings, ShortString} from "@openzeppelin/contracts/utils/ShortStrings.sol";
import "../erc7744/LibERC7744.sol";
/**
 * @title CodeHashDistribution
 * @notice This contract creates immutable. It allows to add metadata to the distribution as well as specify name and version for EIP712 compatibility reasons.
 * @dev This contract is a base for creating distributions that are identified by a deployed functionality (byte code hash).
 */
contract VersionDistribution is UpgradableDistribution {
    bytes32 private immutable metadata;
    address private immutable _reference;
    ShortString public immutable distributionName;
    uint256 public immutable distributionVersion;
    bool public immutable _allowUserCalldata;
    using LibERC7744 for bytes32;
    /**
     * @notice Constructor for the CodeHashDistribution contract.
     * @param codeHash The hash of the code to be distributed.
     * @param _metadata Metadata associated with the code.
     * @param name The name of the distribution.
     * @param version The version number of the distribution.
     */
    constructor(bytes32 codeHash, bytes32 _metadata, string memory name, uint256 version, bool allowUserCalldata) {
        distributionName = ShortStrings.toShortString(name);
        distributionVersion = version;
        metadata = _metadata;
        _reference = codeHash.getContainerOrThrow();
        _allowUserCalldata = allowUserCalldata;
    }
    struct InstantiateData {
        address installer;
        bytes data;
    }
    function instantiate(bytes calldata data) external returns (address[] memory instances, bytes32, uint256) {
        InstantiateData memory instantiateData = abi.decode(data, (InstantiateData));
        return super._instantiate(instantiateData.installer, _allowUserCalldata ? instantiateData.data : bytes(""));
    }

    // @inheritdoc IDistribution
    function sources() internal view virtual override returns (address[] memory, bytes32 name, uint256 version) {
        address[] memory _sources = new address[](1);
        _sources[0] = _reference;
        return (_sources, ShortString.unwrap(distributionName), distributionVersion);
    }
    // @inheritdoc IDistribution
    function contractURI() external view virtual override returns (string memory) {
        return string(abi.encodePacked(metadata)); //ToDo: Add IPFS link with readme!
    }
}
