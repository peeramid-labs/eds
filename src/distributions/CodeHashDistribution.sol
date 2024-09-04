// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "../abstracts/CloneDistribution.sol";

contract CodeHashDistribution is CloneDistribution {
    bytes32 immutable metadata;
    address immutable _reference;

    constructor(bytes32 codeHash, bytes32 _metadata) {
        metadata = _metadata;
        ICodeIndex index = getContractsIndex();
        _reference = index.get(codeHash);
        if (_reference == address(0)) {
            revert("CodeHashDistribution: CodeHash not found in index");
        }
    }

    function sources() internal view virtual override returns (address[] memory) {
        address[] memory _sources = new address[](1);
        _sources[0] = _reference;
        return _sources;
    }

    function getMetadata() public view virtual override returns (string memory) {
        return string(abi.encodePacked(metadata)); //ToDo: Add IPFS link with readme!
    }
}
