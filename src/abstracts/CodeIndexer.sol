// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;

import "../ICodeIndexDep.sol";

abstract contract CodeIndexer {
    //Create2 contract
    ICodeIndex private constant INDEX_CONTRACT = ICodeIndex(0xc0D31d398c5ee86C5f8a23FA253ee8a586dA03Ce);
    constructor() {}
    // @inheritdoc ICodeIndex
    function getContractsIndex() internal pure returns (ICodeIndex) {
        return INDEX_CONTRACT;
    }
    // @inheritdoc ICodeIndex
    function index(address source) internal {
        INDEX_CONTRACT.register(source);
    }
}
