// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC7746} from "../interfaces/IERC7746.sol";
import {IDistributor} from "../interfaces/IDistributor.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
contract SimpleAccessManager is Initializable, IERC7746, ERC165 {
    struct MethodSettings {
        bool isDistributionOnly;
        mapping(address => bool) dissallowedAddresses;
    }

    struct Storage {
        mapping(bytes4 => MethodSettings) methodSettings;
        address target;
        IDistributor distributor;
    }

    bytes32 private constant SACM_STORAGE_POSITION = keccak256("simple.access.manager.storage.position");

    function getStorage() private pure returns (Storage storage s) {
        bytes32 position = SACM_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    struct SimpleAccessManagerInitializer {
        bytes4 selector;
        address[] dissallowedAddresses;
        bool distributionComponentsOnly;
    }

    constructor() {
        _disableInitializers();
    }
    error ERC165CheckFailed(address distributor, bytes4 interfaceId, string interfaceName);
    function initialize(
        SimpleAccessManagerInitializer[] memory methodSettings,
        address target,
        IDistributor distributor
    ) public initializer {
        Storage storage s = getStorage();
        s.distributor = distributor;
        s.target = target;
        if (!ERC165Checker.supportsInterface(address(distributor), type(IDistributor).interfaceId)) {
            revert ERC165CheckFailed(address(distributor), type(IDistributor).interfaceId, "IDistributor");
        }
        uint256 length = methodSettings.length;
        for (uint256 i; i < length; ++i) {
            s.methodSettings[methodSettings[i].selector].isDistributionOnly = methodSettings[i]
                .distributionComponentsOnly;
            uint256 dissalowedMethodsLength = methodSettings[i].dissallowedAddresses.length;
            for (uint256 j; j < dissalowedMethodsLength; ++j) {
                s.methodSettings[methodSettings[i].selector].dissallowedAddresses[
                    methodSettings[i].dissallowedAddresses[j]
                ] = true;
            }
        }
    }

    error OnlyTargetAllowed(address sender, address target);
    error dissallowedAddress(address sender, bytes4 selector);

    function beforeCall(
        bytes memory,
        bytes4 selector,
        address sender,
        uint256 value,
        bytes memory data
    ) external returns (bytes memory) {
        Storage storage s = getStorage();
        if (msg.sender != s.target) {
            revert OnlyTargetAllowed(msg.sender, s.target);
        }
        if (s.methodSettings[selector].dissallowedAddresses[sender]) {
            revert dissallowedAddress(sender, selector);
        } else {
            if (s.methodSettings[selector].isDistributionOnly) {
                return s.distributor.beforeCall(abi.encode(msg.sender), selector, sender, value, data);
            }
            return "";
        }
    }

    function afterCall(
        bytes memory,
        bytes4 selector,
        address sender,
        uint256 value,
        bytes memory data,
        bytes memory beforeCallResult
    ) external {
        Storage storage s = getStorage();
        if (msg.sender != s.target) {
            revert OnlyTargetAllowed(msg.sender, s.target);
        }
        if (s.methodSettings[selector].isDistributionOnly) {
            s.distributor.afterCall(abi.encode(msg.sender), selector, sender, value, data, beforeCallResult);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IERC7746).interfaceId || super.supportsInterface(interfaceId);
    }
}
