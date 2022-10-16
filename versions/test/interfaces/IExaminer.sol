// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IExaminer{
    function initialize(address factory_,address forwarder_,address org_,address admin_,address receiver_,uint256 feeFactor_,address[] calldata allowedTokenList) external;
    function isAdmin(address address_) external view returns(bool);
    function close() external;
    function allowToken(address token) external;
    function changeAdminStatus(address admin_) external;
    function changeReceiver(address newReceiver) external;
}

