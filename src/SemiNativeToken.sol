// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";

import "interchain-token-service/interfaces/IInterchainTokenService.sol";

contract SemiNativeToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable
{
    /*************\
        ERRORS
    /*************/
    error OnlyAdmin();
    error OnlyFactory();
    error Blacklisted();
    error NotApprovedByGateway();

    /*************\
        STORAGE
    /*************/
    IInterchainTokenService public s_its;
    IAxelarGateway public s_gateway;
    bytes32 public s_tokenId;

    address public s_nativeToken;

    /*************\
        EVENTS
    /*************/
    event RewardsDistributed(uint256 amount);

    /*************\
       MODIFIERS
    /*************/

    // modifier isBlacklisted(address _receiver) {
    //     if (s_accessControl.isBlacklistedReceiver(_receiver))
    //         revert Blacklisted();
    //     _;
    // }

    /*************\
     INITIALIZATION
    /*************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IInterchainTokenService _its,
        address _gateway,
        bytes32 _multichainTokenId
    ) public initializer {
        __ERC20_init("Semi Native Interchain Token", "SITS");
        __ERC20Burnable_init();
        __Ownable_init(msg.sender);
        s_its = _its;
        s_gateway = IAxelarGateway(_gateway);
        s_tokenId = _multichainTokenId;
    }

    /***************************\
       EXTERNAL FUNCTIONALITY
    \***************************/

    //for crosschain tx FROM native || from non native
    function interchainTransfer(
        string calldata _destChain,
        bytes calldata _destAddress,
        uint256 _amount
    ) external payable {
        ERC20Upgradeable nativeToken = ERC20Upgradeable(s_nativeToken);

        // Pure Multichain Flow
        if (address(nativeToken) == address(0)) {
            s_its.interchainTransfer(
                s_tokenId,
                _destChain,
                _destAddress,
                _amount,
                "",
                msg.value
            );
        }
        // Native -> Multichain Token flow
        else {
            //1. Transfer native token to address(this) ->  lock native token in semi native
            ERC20Upgradeable(nativeToken).transferFrom(
                msg.sender,
                address(this),
                _amount
            );

            //2. Mint semi native for locked native
            _mint(address(this), _amount);

            //3.
            s_its.interchainTransfer(
                s_tokenId,
                _destChain,
                _destAddress,
                _amount,
                "",
                msg.value
            );
        }
    }

    //for crosschain tx TO native
    function unwrapToNative() external {
        //1. BURN SEMI
        //2. MINT SEMI NATIVE ON DEST CHAIN
        //3. BURN SEMI NATIVE ON DEST
        //4. MINT NATIVE
    }

    //after newly deployed native on same chain
    function claimOwnership() external onlyOwner {
        //1. BURN SEMI NATIVE
        //2. MINT NEWLY DEPLOYED NATIVE TOKEN
    }

    //on dest chain deploy token manager for new ITS token
    function execute(
        bytes32 _commandId,
        string calldata _sourceChain,
        string calldata _sourceAddress,
        bytes calldata _payload
    ) external {
        bytes32 payloadHash = keccak256(_payload);

        if (
            !s_gateway.validateContractCall(
                _commandId,
                _sourceChain,
                _sourceAddress,
                payloadHash
            )
        ) revert NotApprovedByGateway();
    }

    /***************************\
       INTERNAL FUNCTIONALITY
    \***************************/

    function _update(
        address _from,
        address _to,
        uint256 _value
    ) internal override(ERC20Upgradeable) {
        super._update(_from, _to, _value);
    }
}
