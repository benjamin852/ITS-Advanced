// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "axelar-gmp-sdk-solidity/contracts/deploy/Create3Deployer.sol";
import "axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import {StringToAddress, AddressToString} from "axelar-gmp-sdk-solidity/contracts/libs/AddressString.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import "interchain-token-service/interfaces/IInterchainTokenService.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "interchain-token-service/interfaces/IInterchainTokenService.sol";
import "interchain-token-service/interfaces/ITokenManagerType.sol";

import "./NativeTokenV1.sol";
import "./SemiNativeToken.sol";
import "./AccessControl.sol";

contract TokenFactory is Create3Deployer, Initializable {
    using AddressToString for address;

    /*************\
        ERRORS
    /*************/
    error DeploymentFailed();
    error OnlyAdmin();
    error NotApprovedByGateway();

    /*************\
        STORAGE
    /*************/
    IInterchainTokenService public s_its;
    AccessControl public s_accessControl;
    IAxelarGasService public s_gasService;
    IAxelarGateway public s_gateway;

    /*************\
        MODIFIERS
    /*************/
    modifier isAdmin() {
        if (s_accessControl.isAdmin(msg.sender)) revert OnlyAdmin();
        _;
    }

    /*************\
        EVENTS
    /*************/

    /*************\
     INITIALIZATION
    /*************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IInterchainTokenService _its,
        AccessControl _accessControl,
        IAxelarGasService _gasService,
        address _gateway
    ) public initializer {
        s_its = _its;
        s_accessControl = _accessControl;
        s_gasService = _gasService;

        if (_gateway == address(0)) revert("Invalid Gateway Address");
        s_gateway = IAxelarGateway(_gateway);
    }

    /***************************\
       EXTERNAL FUNCTIONALITY
    \***************************/

    //returns params to be used in `deployRemoteMultichainToken`
    function getSemiNativeTokenParams() external view returns (bytes memory) {
        uint256 SEMI_NATIVE_SALT = 123;
        address multiChainTokenTokenAddress = _create3Address(
            bytes32(SEMI_NATIVE_SALT)
        );
        return abi.encode(abi.encode(msg.sender), multiChainTokenTokenAddress);
    }

    //crosschain semi native deployment
    //exec() will deploy create3 token
    function deployRemoteMultichainToken(
        string calldata _destChain,
        bytes calldata _params
    ) external payable {
        uint256 SEMI_NATIVE_SALT = 123;

        // Bytecode + Constructor
        bytes memory creationCode = _getEncodedBytecodeSemiNative();

        bytes memory gmpPayload = abi.encode(
            _destChain,
            SEMI_NATIVE_SALT,
            creationCode,
            _params
        );

        //1. compute address
        (, address multichainTokenAddress) = abi.decode(
            _params,
            (bytes, address)
        );

        string memory tokenAddrString = multichainTokenAddress.toString();

        //2. deploy manager remote for address
        s_its.deployTokenManager(
            bytes32(SEMI_NATIVE_SALT),
            _destChain,
            ITokenManagerType.TokenManagerType.MINT_BURN,
            _params,
            msg.value
        );

        //3. send gmp tx to deploy the token
        s_gasService.payNativeGasForContractCall{value: msg.value}(
            address(this),
            _destChain,
            tokenAddrString,
            gmpPayload,
            msg.sender
        );

        s_gateway.callContract(_destChain, tokenAddrString, gmpPayload);
    }

    //only deploy new token, unrelated to ITS (that is via above function)
    function deployNative(
        uint256 _burnRate,
        uint256 _txFeeRate
    ) external payable isAdmin returns (address) {
        uint256 NATIVE_SALT = 12345;

        // Bytecode + Constructor
        bytes memory creationCode = _getEncodedBytecodeNative(
            _burnRate,
            _txFeeRate
        );

        // Deploy the contract
        address newToken = _deploy(creationCode, bytes32(NATIVE_SALT));
        if (newToken == address(0)) revert DeploymentFailed();

        return newToken;
    }

    //Deploy interchain token for existing native
    function connectExistingNativeToITS() external {}

    /***************************\
       INTERNAL FUNCTIONALITY
    \***************************/

    function _getEncodedBytecodeSemiNative()
        internal
        view
        returns (bytes memory)
    {
        bytes memory bytecode = type(SemiNativeToken).creationCode;

        bytes memory constructorParams = abi.encode();

        return bytes.concat(bytecode, constructorParams);
    }

    function _getEncodedBytecodeNative(
        uint256 _burnRate,
        uint256 _txFeeRate
    ) internal view returns (bytes memory) {
        bytes memory bytecode = type(NativeTokenV1).creationCode;

        bytes memory constructorParams = abi.encode(_burnRate, _txFeeRate);

        return bytes.concat(bytecode, constructorParams);
    }

    function _setupInterchainToken() internal {}

    // //on dest chain deploy token manager for new ITS token
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

        (uint256 SEMI_NATIVE_SALT, bytes memory creationCode) = abi.decode(
            _payload,
            (uint256, bytes)
        );

        // Deploy the contract
        address newToken = _deploy(creationCode, bytes32(SEMI_NATIVE_SALT));
        if (newToken == address(0)) revert DeploymentFailed();
    }
}
