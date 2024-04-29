// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

// import {Setup} from "./Setup.t.sol";

contract TokenV1Test is Test  {
    function testMeWazy() public {
        // uint256 test = token.s_burnRate();
        uint256 wazy = 100;
        assertEq(wazy, wazy);
    }
}
