// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
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

    function testFeeCalcutation(uint256 amount) external {
      vm.assume(amount > 10000);
      uint factor = 100;
      vm.deal(address(this), amount);
      uint256 fee = amount / factor;
      if(fee == 0){
          revert();
        }
      uint256 payableAmount = amount - fee;

      transferNativeFunds(payableAmount, payable(realCaller));
      uint bal = address(this).balance;
      assertEq(fee, bal);
    }

     // Simple functions to avoid code repetition to transfer native currency
    function transferNativeFunds(uint256 amount, address payee) internal {
        (bool success, ) = payable(payee).call{value: amount}("");
        require(success, "Transfer Failed");
    }
}
