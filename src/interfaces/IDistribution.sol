// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import {IContractURI} from "./IContractURI.sol";
/**
 * @title IDistribution
 * @notice Interface for distribution-related functionalities. It can get sources and produce a new instances out from them. It also provides metadata about the distribution.
 * @dev It is highly recommended to keep implementation stateless, and use `immutable` variables for any state. This allows your code to be referred in distributor and respositories via ERC7744. It's also easier to reason about, and more gas efficient.
 * @author Peeramid Labs, 2024
 */
interface IDistribution is IContractURI {
    /**
     * @notice Emitted when a distribution occurs.
     * @param distributor The address of the entity that performed the distribution.
     * @param instances An array of addresses that were produced.
     */
    event Distributed(address indexed distributor, address[] instances);

    /**
     * @notice Instantiates a new instance with the given parameters.
     * @param data The data to be used for instantiation.
     * @return instances An array of addresses that were produced.
     * @return distributionName The name of the distribution.
     * @return distributionVersion The version of the distribution.
     * @dev WARNING: It MUST emit Distributed event.
     */
    function instantiate(
        bytes memory data
    ) external returns (address[] memory instances, bytes32 distributionName, uint256 distributionVersion);

    /**
     * @notice Retrieves the current distribution sources.
     * @return sources An array of addresses that are used for instantiation.
     * @return distributionName The name of the distribution.
     * @return distributionVersion The version of the distribution.
     */
    function get()
        external
        view
        returns (address[] memory sources, bytes32 distributionName, uint256 distributionVersion);
}
