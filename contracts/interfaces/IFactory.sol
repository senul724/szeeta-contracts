// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IFactory{
    function mintCollection( address eventOwner, string memory name, string memory symbol, string memory uri) external returns(address);
}
