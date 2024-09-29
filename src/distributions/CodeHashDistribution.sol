// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../abstracts/CloneDistribution.sol";

contract CodeHashDistribution is CloneDistribution {
    bytes32 immutable private  metadata;
    address immutable private  _reference;
    bytes32 immutable public distributionName;
    uint256 immutable  public distributionVersion;

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

    function sources() internal view virtual override returns (address[] memory, bytes32 name, uint256 version) {
        address[] memory _sources = new address[](1);
        _sources[0] = _reference;
        return (_sources, distributionName, distributionVersion);
    }

    function getMetadata() external view virtual override returns (string memory) {
        return string(abi.encodePacked(metadata)); //ToDo: Add IPFS link with readme!
    }
}
