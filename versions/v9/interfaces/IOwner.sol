// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOwner {
    function getOrg() external view returns(address);
}
