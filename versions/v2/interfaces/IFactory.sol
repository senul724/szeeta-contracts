// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IFactory {
    function createContract(address admin_, address receiver_, bytes32 randomChar_, address[] calldata list_) external returns(address contractAddress_);
    function reasignOrg(address newOrg) external;
    function asignForwarder(address newForwarder) external;
    function asignBase(address newBase) external;
}
