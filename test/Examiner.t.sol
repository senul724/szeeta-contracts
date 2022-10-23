// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/Examiner.sol";

contract ExaminerTest is Test {
    Examiner public examiner;

    address realCaller = 0x15Cf49f835C5545810a2CCd4c8F71B17dc16aE22;

    function setUp() public {
       examiner = new Examiner(2, realCaller);
    }

    function testOwnership() external {
      assertEq(realCaller, examiner.org());
    }

    function testAuthenticity() external {
      vm.prank(realCaller);
      examiner.changeOrg(realCaller);
    }
}
