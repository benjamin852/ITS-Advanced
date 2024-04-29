// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NativeTokenV1.sol";

contract TokenFactory {
    function getEncodedBytecode(
        address _accessControl,
        uint256 _burnRate,
        uint256 _txFeeRate
    ) public pure returns (bytes memory) {
        bytes memory bytecode = type(NativeTokenV1).creationCode;

        bytes memory constructorParams = abi.encode(
            _accessControl,
            _burnRate,
            _txFeeRate
        );

        return bytes.concat(bytecode, constructorParams);
    }

    function deployOtherContract(
        address _accessControl,
        uint256 _burnRate,
        uint256 _txFeeRate
    ) public returns (address) {
        // Bytecode + Constructor
        bytes memory creationCode = getEncodedBytecode(
            _accessControl,
            _burnRate,
            _txFeeRate
        );

        // Deploy the contract
        address newContractAddress;
        assembly {
            newContractAddress := create(
                0,
                add(bytecode, 0x20),
                mload(bytecode)
            )
        }
        require(
            newContractAddress != address(0),
            "Contract deployment failed."
        );
        return newContractAddress;
    }
}
