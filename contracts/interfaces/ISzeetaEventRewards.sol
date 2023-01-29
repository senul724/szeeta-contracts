// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface ISzeetaEventRewards{
    function mint(address contributor, uint eventId) external returns(uint256); 
    function addEventUri(uint eventId, string memory metadataUri) external;
}
