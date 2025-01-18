// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;

import {IERC7744 as ICodeIndex } from "../IERC7744.sol";

abstract contract CodeIndexer {
    //Create2 contract
    ICodeIndex private constant INDEX_CONTRACT = ICodeIndex(0xC0dE1D38E261Db00CDa7b1dDc5584536Cacc90bb);
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
