// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {AddressBytes} from "axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol";

import "interchain-token-service/interfaces/IInterchainTokenExecutable.sol";
import "interchain-token-service/interfaces/IInterchainTokenService.sol";

import "./NativeTokenV1.sol";

contract MultichainToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable
{
    using AddressBytes for bytes;

    /*************\
        ERRORS
    /*************/
    error OnlyAdmin();
    error Blacklisted();
    error NotApprovedByGateway();
    error NativeTokenUnavailable();
    error InvalidClaimAmount();

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
    event TokenClaimed(uint256 amount, address claimer);

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
        bytes calldata _executableAddress, //address(this) on dest
        bytes calldata _receiver,
        uint256 _amount
    ) external payable {
        ERC20Upgradeable nativeToken = ERC20Upgradeable(s_nativeToken);

        // Pure Multichain Flow
        if (address(nativeToken) == address(0)) {
            s_its.interchainTransfer(
                s_tokenId,
                _destChain,
                _receiver,
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
            s_its.callContractWithInterchainToken{value: msg.value}(
                s_tokenId,
                _destChain,
                _executableAddress,
                _amount,
                _receiver,
                msg.value
            );
        }
    }

    //for crosschain tx TO native (i.e. only if native exists)
    function executeWithInterchainToken(
        bytes32,
        string calldata,
        bytes calldata,
        bytes calldata data,
        bytes32,
        address,
        uint256 amount
    ) external {
        address nativeToken = s_nativeToken;
        // bytes memory _data = abi.decode(data, (bytes)); Probably can delete this
        if (nativeToken != address(0)) {
            //1. MINT SEMI NATIVE ON DEST CHAIN -> Done automatically
            //2. BURN SEMI NATIVE ON DEST
            _burn(address(this), amount);
            //3. MINT NATIVE
            NativeTokenV1(nativeToken).mint(data.toAddress(), amount);
        }
    }

    //once native token deployed multichain token holders can burn for native
    function claimNativeToken(uint256 _amountToClaim) external {
        address nativeToken = s_nativeToken;
        if (_amountToClaim > balanceOf(msg.sender)) revert InvalidClaimAmount();
        if (nativeToken == address(0)) revert NativeTokenUnavailable();
        _burn(msg.sender, _amountToClaim);
        NativeTokenV1(nativeToken).mint(msg.sender, _amountToClaim);
        emit TokenClaimed(_amountToClaim, msg.sender);
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
