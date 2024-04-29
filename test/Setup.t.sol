// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {NativeTokenV1} from "../src/NativeTokenV1.sol";
import {AccessControl} from "../src/AccessControl.sol";

contract Setup is Test {
    bytes32 constant IMPL_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    NativeTokenV1 public token;

    AccessControl public accessControl;

    constructor() {
        address accessProxy = Upgrades.deployTransparentProxy(
            "AccessControl.sol",
            vm.addr(1),
            abi.encodeCall(AccessControl.initialize, (vm.addr(1)))
        );
        accessControl = AccessControl(accessProxy);

        address tokenProxy = Upgrades.deployTransparentProxy(
            "NativeTokenV1.sol",
            vm.addr(1),
            abi.encodeCall(
                NativeTokenV1.initialize,
                (accessControl, 20000, 10000)
            )
        );
        token = NativeTokenV1(tokenProxy);
    }
}
