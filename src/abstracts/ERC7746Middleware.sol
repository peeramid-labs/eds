// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
import "../libraries/LibMiddleware.sol";

abstract contract ERC7746Middleware {
    modifier ERC7746Customised(bytes4 _selector, address sender, bytes calldata data, uint256 value) {
        bytes[] memory layerReturns = LibMiddleware.beforeCall(_selector, sender, data, value);
        _;
        LibMiddleware.afterCall(_selector, sender, data, value, layerReturns);
    }

    modifier ERC7746() {
        bytes[] memory layerReturns = LibMiddleware.beforeCall(msg.sig, msg.sender, msg.data, msg.value);
        _;
        LibMiddleware.afterCall(msg.sig, msg.sender, msg.data, msg.value, layerReturns);
    }
}
