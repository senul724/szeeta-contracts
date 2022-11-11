// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ISzeetaEventRewards{
    function mint(address contributor, uint eventId) external returns(uint256); 
    function addEventUri(uint eventId, string memory metadataUri) external;
}
