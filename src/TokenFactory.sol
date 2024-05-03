// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import {StringToAddress, AddressToString} from "axelar-gmp-sdk-solidity/contracts/libs/AddressString.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import "interchain-token-service/interfaces/IInterchainTokenService.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "interchain-token-service/interfaces/IInterchainTokenService.sol";
import "interchain-token-service/interfaces/ITokenManagerType.sol";
import "forge-std/console2.sol";

// import "axelar-gmp-sdk-solidity/contracts/deploy/Create3.sol";
import "./helpers/Create3.sol";
import "./NativeTokenV1.sol";
import "./MultichainToken.sol";
import "./AccessControl.sol";

// contract TokenFactory is Create3Deployer, Initializable {
contract TokenFactory is Initializable, Create3 {
    using AddressToString for address;

    /*************\
        ERRORS
    /*************/
    error DeploymentFailed();
    error OnlyAdmin();
    error NotApprovedByGateway();
    error NativeTokenAlreadyDeployed();
    error MultichainTokenAlreadyDeployed();

    /*************\
        STORAGE
    /*************/
    IInterchainTokenService public s_its;
    AccessControl public s_accessControl;
    IAxelarGasService public s_gasService;
    IAxelarGateway public s_gateway;
    address public s_nativeToken;
    address public s_multichainToken;

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
    event NativeTokenDeployed(address tokenAddress);
    event MultichainTokenDeployed(address tokenAddress);

    /*************\
     INITIALIZATION
    /*************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IInterchainTokenService _its,
        IAxelarGasService _gasService,
        IAxelarGateway _gateway,
        AccessControl _accessControl
    ) public initializer {
        s_its = _its;
        s_gasService = _gasService;
        s_accessControl = _accessControl;
        s_gateway = _gateway;
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

    //exec() will deploy create3 token
    //crosschain semi native deployment
    function deployRemoteMultichainToken(
        string calldata _destChain,
        bytes calldata _params
    ) external payable {
        uint256 SEMI_NATIVE_SALT = 123;

        //Add revert if token already deployed

        //1. deploy manager remote for address
        bytes32 multichainTokenId = s_its.deployTokenManager(
            bytes32(SEMI_NATIVE_SALT),
            _destChain,
            ITokenManagerType.TokenManagerType.MINT_BURN,
            _params,
            msg.value
        );

        // Bytecode + Constructor
        bytes memory creationCode = _getEncodedBytecodeSemiNative(
            multichainTokenId
        );

        bytes memory gmpPayload = abi.encode(
            _destChain,
            SEMI_NATIVE_SALT,
            creationCode,
            _params
        );

        //2. get computed multichainToken address
        (, address multichainTokenAddress) = abi.decode(
            _params,
            (bytes, address)
        );

        string memory tokenAddrString = multichainTokenAddress.toString();

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
    //same chain
    function deployNative(
        uint256 _burnRate,
        uint256 _txFeeRate
    ) external payable isAdmin returns (address newTokenProxy) {
        if (s_nativeToken != address(0)) revert NativeTokenAlreadyDeployed();

        uint256 NATIVE_SALT_IMPL = 123456;
        uint256 NATIVE_SALT_PROXY = 12345;

        // Deploy  implementation
        address newTokenImpl = _create3(
            type(NativeTokenV1).creationCode,
            bytes32(NATIVE_SALT_IMPL)
        );
        if (newTokenImpl == address(0)) revert DeploymentFailed();

        // Bytecode + Constructor
        bytes memory proxyCreationCode = _getEncodedCreationCodeNative(
            newTokenImpl,
            _burnRate,
            _txFeeRate
        );

        //Deploy proxy
        newTokenProxy = _create3(proxyCreationCode, bytes32(NATIVE_SALT_PROXY));
        if (newTokenProxy == address(0)) revert DeploymentFailed();
        emit NativeTokenDeployed(newTokenProxy);
        s_nativeToken = newTokenProxy;
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

        (uint256 SEMI_NATIVE_SALT, bytes memory creationCode) = abi.decode(
            _payload,
            (uint256, bytes)
        );

        // Deploy the contract
        address newToken = _create3(creationCode, bytes32(SEMI_NATIVE_SALT));
        if (newToken == address(0)) revert DeploymentFailed();
        emit MultichainTokenDeployed(newToken);
        s_multichainToken = newToken;
    }

    function getExpectedAddress(bytes32 _salt) public view returns (address) {
        return _create3Address(_salt);
    }

    /***************************\
       INTERNAL FUNCTIONALITY
    \***************************/

    function _getEncodedBytecodeSemiNative(
        bytes32 _multichainTokenId
    ) internal view returns (bytes memory) {
        bytes memory bytecode = type(MultichainToken).creationCode;

        bytes memory constructorParams = abi.encode(
            s_its,
            s_gateway,
            _multichainTokenId
        );

        return bytes.concat(bytecode, constructorParams);
    }

    function _getEncodedCreationCodeNative(
        address _liveImpl,
        uint256 _burnRate,
        uint256 _txFeeRate
    ) internal returns (bytes memory proxyCreationCode) {
        bytes memory nativeTokenImpl = type(NativeTokenV1).creationCode;

        // bytes memory constructorParams = abi.encode(
        //     _burnRate,
        //     _txFeeRate,
        //     address(0)
        // );

        // return bytes.concat(bytecode, constructorParams);

        // Deploy ProxyAdmin
        ProxyAdmin proxyAdmin = new ProxyAdmin(msg.sender);

        bytes memory initData = abi.encodeWithSelector(
            NativeTokenV1.initialize.selector,
            s_accessControl,
            _burnRate,
            _txFeeRate
        );

        proxyCreationCode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(_liveImpl, address(proxyAdmin), initData)
        );
    }
}
