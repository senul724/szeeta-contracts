// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IExaminer{
    function initialize(address org_,address admin_,address receiver_,uint256 feeFactor_,address[] memory allowedTokenList) external;
}
