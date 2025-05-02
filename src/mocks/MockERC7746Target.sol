// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "../interfaces/IERC7746.sol";

contract MockERC7746Target {
    address public middleware;

    error MiddlewareReverted(string reason);

    function setMiddleware(address _middleware) external {
        middleware = _middleware;
    }

    function executeWithSelector(bytes4 selector, bytes calldata data) external returns (bytes memory) {
        // Call middleware.beforeCall
        try IERC7746(middleware).beforeCall("", selector, msg.sender, 0, data) returns (bytes memory beforeResult) {
            // The actual execution would happen here
            bytes memory result = "0x1234"; // Mock result

            // Call middleware.afterCall
            IERC7746(middleware).afterCall("", selector, msg.sender, 0, data, beforeResult);

            return result;
        } catch Error(string memory reason) {
            revert MiddlewareReverted(reason);
        } catch {
            revert MiddlewareReverted("unknown error");
        }
    }
}