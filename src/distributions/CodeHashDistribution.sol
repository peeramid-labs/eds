// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../abstracts/CloneDistribution.sol";

/**
 * @title CodeHashDistribution
 * @notice This contract creates immutable. It allows to add metadata to the distribution as well as specify name and version for EIP712 compatability reasons.
 * @dev This contract is a base for creating distributions that are identified by a deployed functionality (byte code hash).
 */
contract CodeHashDistribution is CloneDistribution {
    bytes32 private immutable metadata;
    address private immutable _reference;
    bytes32 public immutable distributionName;
    uint256 public immutable distributionVersion;

    /**
     * @notice Constructor for the CodeHashDistribution contract.
     * @param codeHash The hash of the code to be distributed.
     * @param _metadata Metadata associated with the code.
     * @param name The name of the distribution.
     * @param version The version number of the distribution.
     */
    constructor(bytes32 codeHash, bytes32 _metadata, bytes32 name, uint256 version) {
        distributionName = name;
        distributionVersion = version;
        metadata = _metadata;
        ICodeIndex index = getContractsIndex();
        _reference = index.get(codeHash);
        if (_reference == address(0)) {
            revert CodeNotFoundInIndex(codeHash);
        }
    }

    function instantiate(bytes memory) external returns (address[] memory instances, bytes32, uint256) {
        return super._instantiate();
    }

    // @inheritdoc IDistribution
    function sources() internal view virtual override returns (address[] memory, bytes32 name, uint256 version) {
        address[] memory _sources = new address[](1);
        _sources[0] = _reference;
        return (_sources, distributionName, distributionVersion);
    }
    // @inheritdoc IDistribution
    function contractURI() external view virtual override returns (string memory) {
        return string(abi.encodePacked(metadata)); //ToDo: Add IPFS link with readme!
    }
}
