// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

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

    /*************\
        STORAGE
    /*************/

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

    function initialize() public initializer {
        __ERC20_init("Semi Native Interchain Token", "SITS");
        __ERC20Burnable_init();
        __Ownable_init(msg.sender);
    }

    /***************************\
       EXTERNAL FUNCTIONALITY
    \***************************/
    function interchainTransfer(uint256 _amount) external { 
        //1. nativeToken.transferFrom(msg.sender, address(this), _amount); -> lock native token in semi native
    }

    //for crosschain tx
    function unwrapToNative() external {
        //1. BURN SEMI
        //2. MINT SEMI NATIVE ON DEST CHAIN
        //3. BURN SEMI NATIVE ON DEST
        //4. MINT NATIVE
    }

    //for newly deployed native on same chain
    function claimOwnership() external onlyOwner {
        //1. BURN SEMI NATIVE
        //2. MINT NEWLY DEPLOYED NATIVE TOKEN
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
