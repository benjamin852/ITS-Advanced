// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "interchain-token-service/interfaces/IInterchainTokenService.sol";
import "axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import "../src/TokenFactory.sol";
import "../src/helpers/Create3Address.sol";
import "../src/AccessControl.sol";

import {Setup} from "./Setup.t.sol";

contract Initialization is Setup {
    function testInit() public view {
        assertEq(address(its), address(factory.s_its()));
        assertEq(address(gasService), address(factory.s_gasService()));
        assertEq(address(gateway), address(factory.s_gateway()));
        assertEq(address(accessControl), address(factory.s_accessControl()));
    }

    function testRevertIfCalledTwice() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        factory.initialize(
            IInterchainTokenService(vm.addr(2)),
            IAxelarGasService(address(0)),
            IAxelarGateway(address(0)),
            AccessControl(address(0))
        );
    }
}

contract NativeTokenDeployment is Setup, Create3Address {
    uint256 public burnRate = 10000;
    uint256 public feeRate = 20000;

    event NativeTokenDeployed(address tokenAddress);

    //reverts if already deployed
    function testRevertIfDeployed() public {
        factory.deployNative(burnRate, feeRate);
        vm.expectRevert(TokenFactory.NativeTokenAlreadyDeployed.selector);
        factory.deployNative(burnRate, feeRate);
    }

    function testDeploysToExpectedAddr() public {
        uint256 NATIVE_SALT_PROXY = 12345;

        address expectedAddr = factory.getExpectedAddress(
            bytes32(NATIVE_SALT_PROXY)
        );

        vm.expectEmit(true, false, false, true);
        emit NativeTokenDeployed(expectedAddr);
        factory.deployNative(burnRate, feeRate);
    }
}

// contract SemiNativeTokenDeployment is Setup {}
