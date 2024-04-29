// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {Setup} from "./Setup.t.sol";

contract Initialization is Setup {
    function testInit() public view {
        assertEq(address(token.s_accessControl()), address(accessControl));
        assertEq(token.s_burnRate(), 20000);
        assertEq(token.s_txFeeRate(), 10000);
        assertEq(token.name(), "Interchain Token");
        assertEq(token.symbol(), "ITS");
    }
}
