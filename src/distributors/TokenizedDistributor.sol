// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Distributor.sol";

abstract contract TokenizedDistributor is Distributor, Initializable {
    event InstantiationCostChanged(bytes32 indexed id, uint256 cost);

    struct TokenizedDistributorStore {
        IERC20 paymentToken;
        address beneficiary;
        mapping(bytes32 codeHash => uint256) instantiationCosts;
        uint256 defaultInstantiationCost;
    }

    function instantiationCosts(bytes32 distributorsId) public view returns (uint256) {
        return getTokenizedDistributorStore().instantiationCosts[distributorsId];
    }

    function defaultInstantiationCost() public view returns (uint256) {
        return getTokenizedDistributorStore().defaultInstantiationCost;
    }

    function paymentToken() public view returns (IERC20) {
        return getTokenizedDistributorStore().paymentToken;
    }

    function beneficiary() public view returns (address) {
        return getTokenizedDistributorStore().beneficiary;
    }



    function getTokenizedDistributorStore()
        internal
        pure
        returns (TokenizedDistributorStore storage tokenizedDistributorStore)
    {
        bytes32 TOKENIZED_DISTRIBUTOR_STORAGE_POSITION = keccak256("distributor.tokenized.distributor.store");
        assembly {
            tokenizedDistributorStore.slot := TOKENIZED_DISTRIBUTOR_STORAGE_POSITION
        }
    }
    constructor(IERC20 token, uint256 defaultCost, address _beneficiary) Distributor() {
        initialize(token, defaultCost, _beneficiary);
    }

    function initialize(IERC20 token, uint256 defaultCost, address _beneficiary) public initializer {
        TokenizedDistributorStore storage tokenizedDistributorStore = getTokenizedDistributorStore();
        tokenizedDistributorStore.paymentToken = token;
        tokenizedDistributorStore.defaultInstantiationCost = defaultCost;
        tokenizedDistributorStore.beneficiary = _beneficiary;
    }

    /**
     * @notice Sets instantiation cost on a specific instantiation id
     * @param distributorsId distributors id
     * @param cost cost of instantiation
     */
    function _setInstantiationCost(bytes32 distributorsId, uint256 cost) internal {
        TokenizedDistributorStore storage tokenizedDistributorStore = getTokenizedDistributorStore();
        tokenizedDistributorStore.instantiationCosts[distributorsId] = cost;
        emit InstantiationCostChanged(distributorsId, cost);
    }

    /**
     * @inheritdoc Distributor
     */
    function _addDistribution(
        bytes32 codeHash,
        address initializerAddress,
        string memory readableName
    ) internal override returns (bytes32 distributorsId) {
        TokenizedDistributorStore storage tokenizedDistributorStore = getTokenizedDistributorStore();
        distributorsId = super._addDistribution(codeHash, initializerAddress, readableName);
        _setInstantiationCost(distributorsId, tokenizedDistributorStore.defaultInstantiationCost);
    }

    function _addDistribution(
        address repository,
        address initializer,
        LibSemver.VersionRequirement memory requirement,
        string memory readableName
    ) internal override returns (bytes32 distributorsId) {
        TokenizedDistributorStore storage tokenizedDistributorStore = getTokenizedDistributorStore();
        distributorsId = super._addDistribution(repository, initializer, requirement, readableName);
        _setInstantiationCost(distributorsId, tokenizedDistributorStore.defaultInstantiationCost);
    }

    /**
     * @inheritdoc Distributor
     */
    function _instantiate(
        bytes32 distributorsId,
        bytes memory args
    )
        internal
        virtual
        override
        returns (address[] memory instances, bytes32 distributionName, uint256 distributionVersion)
    {
        TokenizedDistributorStore storage tokenizedDistributorStore = getTokenizedDistributorStore();
        SafeERC20.safeTransferFrom(
            tokenizedDistributorStore.paymentToken,
            msg.sender,
            tokenizedDistributorStore.beneficiary,
            tokenizedDistributorStore.instantiationCosts[distributorsId]
        );
        return super._instantiate(distributorsId, args);
    }

    function _setBeneficiary(address _beneficiary) internal {
        TokenizedDistributorStore storage tokenizedDistributorStore = getTokenizedDistributorStore();
        tokenizedDistributorStore.beneficiary = _beneficiary;
    }
}
