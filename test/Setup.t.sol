// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "interchain-token-service/interfaces/IInterchainTokenService.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {AccessControl} from "../src/AccessControl.sol";

contract Setup is Test {
    bytes32 constant IMPL_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    TokenFactory public factory;

    AccessControl public accessControl;

    constructor() {
        address accessProxy = Upgrades.deployTransparentProxy(
            "AccessControl.sol",
            vm.addr(1),
            abi.encodeCall(AccessControl.initialize, (vm.addr(1)))
        );
        accessControl = AccessControl(accessProxy);

        // address tokenProxy = Upgrades.deployTransparentProxy(
        //     "TokenFactory.sol",
        //     vm.addr(1),
        //     abi.encodeCall(
        //         TokenFactory.initialize,
        //         (its, gasService, gateway, accessProxy)
        //     )
        // );
        // token = IInterchainTokenService();
    }
}
