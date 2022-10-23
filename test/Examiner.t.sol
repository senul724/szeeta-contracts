// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/Examiner.sol";

contract ExaminerTest is Test {
    Examiner public examiner;
    function setUp() public {
       examiner = new Examiner(2, msg.sender);
    }

    function testOwner() external {
        address organ = examiner.org();
        assertEq(organ, msg.sender);
    }
}
