// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IFactory {
    function createContract(address receiver_, uint randomNo_, address[] memory list_) external returns(address contractAddress_);
    function reasignOrg(address newOrg) external;
    function reasignForwarder(address newForwarder) external;
}