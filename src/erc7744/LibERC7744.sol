// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;

import {IERC7744 as ICodeIndex} from "./IERC7744.sol";

library LibERC7744 {
    //Create2 contract
    ICodeIndex private constant INDEX_CONTRACT = ICodeIndex(0xC0De1D1126b6D698a0073A4e66520111cEe22F62);
    // @inheritdoc ICodeIndex
    function getContractsIndex() internal pure returns (ICodeIndex) {
        return INDEX_CONTRACT;
    }
    // @inheritdoc ICodeIndex
    function index(address source) internal {
        INDEX_CONTRACT.register(source);
    }

    function getContainer(bytes32 id) internal view returns (address) {
        return getContractsIndex().get(id);
    }

    error AddressNotFound(bytes32 id);

    function getContainerOrThrow(bytes32 id) internal view returns (address) {
        address container = getContainer(id);
        if (container == address(0)) revert AddressNotFound(id);
        return container;
    }
}

