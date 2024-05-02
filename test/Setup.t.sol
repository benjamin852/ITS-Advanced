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

    constructor() {
        string memory network = vm.envString("NETWORK");

        // Retrieve the private key directly from environment variables
        string memory privateKeyHex = vm.envString("LOCAL_PRIVATE_KEY");

        // Basic validation to check if the private key is empty
        if (bytes(privateKeyHex).length == 0) {
            revert(
                "LOCAL_PRIVATE_KEY is not set in the environment variables."
            );
        }

        // Convert the hexadecimal private key to a uint256
        uint256 privateKey = uint256(bytes32(vm.parseBytes(privateKeyHex)));

        (
            address gateway,
            address gasService,
            address create3Deployer,
            address its
        ) = getNetworkDetails(network);

        address accessProxy = Upgrades.deployTransparentProxy(
            "AccessControl.sol",
            vm.addr(1),
            abi.encodeCall(AccessControl.initialize, (vm.addr(1)))
        );
        accessControl = AccessControl(accessProxy);

        address tokenProxy = Upgrades.deployTransparentProxy(
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
        // token = IInterchainTokenService();
    }
}
