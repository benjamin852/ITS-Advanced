// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "interchain-token-service/interfaces/IInterchainTokenService.sol";
import "axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
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
