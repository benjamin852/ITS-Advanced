// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "interchain-token-service/interfaces/IInterchainTokenService.sol";
import "../src/TokenFactory.sol";
import "../src/AccessControl.sol";
import "../src/MultichainToken.sol";
import "../script/local/NetworkDetailsBase.s.sol";

contract Setup is Test, NetworkDetailsBase {
    bytes32 constant IMPL_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    TokenFactory public factory;

    AccessControl public accessControl;

    address public gateway;
    address public gasService;
    address public create3Deployer;
    address public its;

    string[] networks = [
        "ethereum",
        "avalanche",
        "moonbeam",
        "fantom",
        "polygon"
    ];

    constructor() {
        for (uint i = 0; i < networks.length; i++) {
            (gateway, gasService, create3Deployer, its) = getNetworkDetails(
                networks[i]
            );
        }

        address accessProxy = Upgrades.deployTransparentProxy(
            "AccessControl.sol",
            vm.addr(1),
            abi.encodeCall(AccessControl.initialize, (vm.addr(1)))
        );
        accessControl = AccessControl(accessProxy);

        address tokenFactory = Upgrades.deployTransparentProxy(
            "TokenFactory.sol",
            vm.addr(1),
            abi.encodeCall(
                TokenFactory.initialize,
                (
                    IInterchainTokenService(its),
                    IAxelarGasService(gasService),
                    IAxelarGateway(gateway),
                    accessControl
                )
            )
        );
        factory = TokenFactory(tokenFactory);
    }
}
