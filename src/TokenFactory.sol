// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "axelar-gmp-sdk-solidity/deploy/Create3Deployer.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./NativeTokenV1.sol";
import "./SemiNativeToken.sol";

contract TokenFactory is Create3Deployer, Initializable {
    /*************\
        ERRORS
    /*************/
    error DeploymentFailed();

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

    /***************************\
       EXTERNAL FUNCTIONALITY
    \***************************/

    function deploySemiNative() external returns (address) {
        uint256 SEMI_NATIVE_SALT = 123;

        // Bytecode + Constructor
        bytes memory creationCode = _getEncodedBytecodeSemiNative();

        // Deploy the contract
        address newToken = _deploy(creationCode, bytes32(SEMI_NATIVE_SALT));
        if (newToken == address(0)) revert DeploymentFailed();
        return newToken;
    }

    function deployNative(
        uint256 _burnRate,
        uint256 _txFeeRate
    ) external returns (address) {
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

    function connectExistingNativeToITS() external

    /***************************\
       INTERNAL FUNCTIONALITY
    \***************************/

    function _getEncodedBytecodeSemiNative()
        internal
        view
        returns (bytes memory)
    {
        bytes memory bytecode = type(SemiNative).creationCode;

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
}
