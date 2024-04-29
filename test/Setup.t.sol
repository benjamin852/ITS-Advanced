// // SPDX-License-Identifier: Unlicense
// pragma solidity ^0.8.20;

// import "forge-std/Test.sol";
// import "forge-std/console2.sol";

// import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
// import {NativeTokenV1} from "../src/NativeTokenV1.sol";
// import {AccessControl} from "../src/AccessControl.sol";

// import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
// import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

// contract Setup is Test {
//     bytes32 constant IMPL_SLOT =
//         bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
//     NativeTokenV1 public token;
//     ProxyAdmin public admin;

//     // AccessControl public accessControl;

//     constructor() {
//         // address tokenInstance = Upgrades.deployTransparentProxy(
//         //     "NativeTokenV1.sol",
//         //     vm.addr(1),
//         //     abi.encodeCall(NativeTokenV1.initialize, (20000, 10000))
//         // );
//         admin = new ProxyAdmin(vm.addr(1));

//         NativeTokenV1 tokenImpl = new NativeTokenV1();
//         TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
//             address(tokenImpl),
//             address(admin),
//             ""
//         );
//         token = NativeTokenV1(address(proxy));
//         token.initialize(20000, 10000);
//     }
// }
